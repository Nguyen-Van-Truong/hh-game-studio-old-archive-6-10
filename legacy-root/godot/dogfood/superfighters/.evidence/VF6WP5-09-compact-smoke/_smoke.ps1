$ErrorActionPreference = "Stop"
$prod = "D:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\hh-game-studio\godot\dogfood\superfighters"
$godot = Join-Path $env:LOCALAPPDATA "HHGodotAgent\tooling\godot-4.7.1-stable\bin\Godot_v4.7.1-stable_win64.exe"
$ev = Join-Path $prod ".evidence\VF6WP5-09-compact-smoke"
$log = Join-Path $ev "compact.log"
New-Item -ItemType Directory -Force -Path $ev | Out-Null
if (-not ("HhGodotHost.Runner" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.IO;
using System.Text;
namespace HhGodotHost {
  public static class Runner {
    public static int Run(string exe, string args, string workdir, string stdoutPath, string stderrPath, bool createNoWindow) {
      var psi = new ProcessStartInfo();
      psi.FileName = exe;
      psi.Arguments = args;
      psi.WorkingDirectory = workdir;
      psi.UseShellExecute = false;
      psi.RedirectStandardOutput = true;
      psi.RedirectStandardError = true;
      psi.CreateNoWindow = createNoWindow;
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
          if (!p.Start()) return 1;
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
$env:HH_VF_BOTS_COMPACT = "1"
$env:HH_VF_EVIDENCE_DIR = $ev
$code = [HhGodotHost.Runner]::Run($godot, "--path `"$prod`" --headless --script res://tests/run_bots.gd", $prod, $log, ($log + ".err"), $true)
if (Test-Path ($log + ".err")) {
    $errText = Get-Content -Raw -Path ($log + ".err") -ErrorAction SilentlyContinue
    if ($errText) { Add-Content -Path $log -Value $errText }
}
Remove-Item Env:HH_VF_BOTS_COMPACT -ErrorAction SilentlyContinue
Remove-Item Env:HH_VF_EVIDENCE_DIR -ErrorAction SilentlyContinue
Write-Output "SMOKE_EXIT=$code"
exit $code
