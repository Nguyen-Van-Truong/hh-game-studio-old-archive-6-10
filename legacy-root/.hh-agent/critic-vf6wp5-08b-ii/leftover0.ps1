$ErrorActionPreference = "Stop"
$iso = "d:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\hh-game-studio\.hh-agent\critic-vf6wp5-08b-ii\iso"
$out = "d:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\hh-game-studio\.hh-agent\critic-vf6wp5-08b-ii"
$godot = Join-Path $env:LOCALAPPDATA "HHGodotAgent\tooling\godot-4.7.1-stable\bin\Godot_v4.7.1-stable_win64.exe"
$checkLog = Join-Path $out "check_bots.log"
$godotLog = Join-Path $out "iso_headless.log"
$godotErr = Join-Path $out "iso_headless.log.err"
$proofPath = Join-Path $out "leftover_proof.json"

if (-not ("HhCritic08b.Runner" -as [type])) {
  Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.IO;
using System.Text;
namespace HhCritic08b {
  public static class Runner {
    public static int Run(string exe, string args, string workdir, string stdoutPath, string stderrPath) {
      var psi = new ProcessStartInfo();
      psi.FileName = exe;
      psi.Arguments = args;
      psi.WorkingDirectory = workdir;
      psi.UseShellExecute = false;
      psi.RedirectStandardOutput = true;
      psi.RedirectStandardError = true;
      psi.CreateNoWindow = true;
      psi.StandardOutputEncoding = new UTF8Encoding(false);
      psi.StandardErrorEncoding = new UTF8Encoding(false);
      using (var p = new Process()) {
        p.StartInfo = psi;
        using (var outFile = new StreamWriter(stdoutPath, false, new UTF8Encoding(false)))
        using (var errFile = new StreamWriter(stderrPath, false, new UTF8Encoding(false))) {
          outFile.AutoFlush = true;
          errFile.AutoFlush = true;
          var gate = new object();
          p.OutputDataReceived += (s, e) => {
            if (e.Data == null) return;
            lock (gate) { outFile.WriteLine(e.Data); }
          };
          p.ErrorDataReceived += (s, e) => {
            if (e.Data == null) return;
            lock (gate) { errFile.WriteLine(e.Data); }
          };
          if (!p.Start()) { return 1; }
          Console.WriteLine("GODOT_PID=" + p.Id);
          p.BeginOutputReadLine();
          p.BeginErrorReadLine();
          p.WaitForExit();
          p.WaitForExit(10000);
          lock (gate) { outFile.Flush(); errFile.Flush(); }
          return p.ExitCode;
        }
      }
    }
  }
}
"@
}

function Count-IsoLeftover {
  @(Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match "Godot" -and $_.CommandLine -and ($_.CommandLine -like "*$iso*")
  }).Count
}

Remove-Item Env:HH_VF_BOTS_COMPACT -ErrorAction SilentlyContinue
$env:HH_VF_EVIDENCE_DIR = Join-Path $out "evidence"
New-Item -ItemType Directory -Force -Path $env:HH_VF_EVIDENCE_DIR | Out-Null

$before = Count-IsoLeftover
Write-Output "LEFTOVER_ISO_BEFORE=$before"
if ($before -ne 0) { throw "iso leftover=$before before start; refuse" }

$sw = [System.Diagnostics.Stopwatch]::StartNew()
python (Join-Path $iso "tests\check_bots.py") | Tee-Object -FilePath $checkLog
$checkExit = $LASTEXITCODE
$sw.Stop()
$afterCheck = Count-IsoLeftover
Write-Output "CHECK_EXIT=$checkExit leftover=$afterCheck elapsed=$([math]::Round($sw.Elapsed.TotalSeconds,1))"
if ($checkExit -ne 0) { throw "check_bots failed on iso" }

$args = "--path `"$iso`" --headless --script res://tests/run_bots.gd"
$sw2 = [System.Diagnostics.Stopwatch]::StartNew()
$code = [HhCritic08b.Runner]::Run($godot, $args, $iso, $godotLog, $godotErr)
$sw2.Stop()
Start-Sleep -Seconds 2
$after = Count-IsoLeftover
$elapsed = [math]::Round($sw2.Elapsed.TotalSeconds, 1)
Write-Output "HEADLESS_HOST_EXIT=$code leftover=$after elapsed=$elapsed host=WaitForExit"
$proof = [ordered]@{
  leftover = $after
  after_check = $afterCheck
  after_headless = $after
  path = $iso
  counted_iso_path = $iso
  scan = "Win32_Process Name~Godot; CommandLine contains critic-vf6wp5-08b-ii iso --path only"
  engine_exe = $godot
  check_exit = $checkExit
  headless_host_exit = $code
  headless_elapsed_sec = $elapsed
  host = "System.Diagnostics.Process.WaitForExit"
  hung = $false
  note = "critic II leftover-0 on iso --path only; did not touch product or old critic-vf6wp5-08-ii"
}
[System.IO.File]::WriteAllText($proofPath, (($proof | ConvertTo-Json -Depth 6) + "`n"))
if ($code -ne 0) { exit $code }
if ($after -ne 0) { exit 2 }
exit 0
