$ErrorActionPreference = "Stop"
$iso = "d:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\hh-game-studio\.hh-agent\critic-vf6wp5-10-ii-r2\iso"
$work = "d:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\hh-game-studio\.hh-agent\critic-vf6wp5-10-ii-r2"
$ev = Join-Path $work "iso-headless-ev"
$log = Join-Path $work "iso_headless.log"
$err = Join-Path $work "iso_headless.log.err"
$godotEngine = Join-Path $env:LOCALAPPDATA "HHGodotAgent\tooling\godot-4.7.1-stable\bin\Godot_v4.7.1-stable_win64.exe"
New-Item -ItemType Directory -Force -Path $ev | Out-Null

if (-not ("HhCriticIIR2.Runner" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.IO;
using System.Text;
namespace HhCriticIIR2 {
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
          Console.WriteLine("GODOT_PID=" + p.Id + " exe=" + exe);
          p.BeginOutputReadLine();
          p.BeginErrorReadLine();
          p.WaitForExit();
          p.WaitForExit(10000);
          lock (gate) {
            outFile.Flush();
            errFile.Flush();
          }
          return p.ExitCode;
        }
      }
    }
  }
}
"@
}

function Count-IsoLeftover {
    $needle = "critic-vf6wp5-10-ii-r2\iso"
    @(Get-CimInstance Win32_Process | Where-Object {
        $_.Name -match "Godot" -and $_.CommandLine -and ($_.CommandLine -like "*$needle*")
    }).Count
}

function Quote-Arg([string]$value) {
    if ($value -match '[\s"]') {
        return '"' + ($value -replace '"', '\"') + '"'
    }
    return $value
}

$before = Count-IsoLeftover
if ($before -ne 0) { throw "leftover=$before before iso headless" }

Remove-Item Env:HH_VF_BOTS_COMPACT -ErrorAction SilentlyContinue
$env:HH_VF_EVIDENCE_DIR = $ev
$env:HH_VF_RUN_ID = "VF6WP5-20260905-ASIA-SAIGON-10"

$args = @(
    "--path", $iso,
    "--headless",
    "--script", "res://tests/run_bots.gd"
)
$argStr = ($args | ForEach-Object { Quote-Arg $_ }) -join " "
Write-Output "HOST iso=$iso"
Write-Output "HOST leftover_before=$before"
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$code = [HhCriticIIR2.Runner]::Run($godotEngine, $argStr, $iso, $log, $err)
$sw.Stop()
Start-Sleep -Seconds 2
$after = Count-IsoLeftover
$elapsed = [math]::Round($sw.Elapsed.TotalSeconds, 1)
Write-Output "HOST_EXIT=$code leftover=$after elapsed=$elapsed host=System.Diagnostics.Process.WaitForExit"
$proof = [ordered]@{
    leftover             = $after
    after_headless       = $after
    path                 = $iso
    counted_product_path = $iso
    scan                 = "Win32_Process Name~Godot; CommandLine contains critic-vf6wp5-10-ii-r2\iso"
    engine_exe           = $godotEngine
    headless_host_exit   = [int]$code
    headless_elapsed_sec = $elapsed
    host                 = "System.Diagnostics.Process.WaitForExit"
    note                 = "critic II r2 leftover-0 on ii-r2 iso --path only; no banner remap"
}
[System.IO.File]::WriteAllText((Join-Path $work "iso_leftover_proof.json"), (($proof | ConvertTo-Json -Depth 6) + "`n"))
if ($err -and (Test-Path $err)) {
    $errText = Get-Content -Raw -Path $err -ErrorAction SilentlyContinue
    if ($errText) { Add-Content -Path $log -Value $errText }
}
exit [int]$code
