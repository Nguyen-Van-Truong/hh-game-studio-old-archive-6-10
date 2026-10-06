$ErrorActionPreference = "Stop"
$prod = "D:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\hh-game-studio\godot\dogfood\superfighters"
$godot = Join-Path $env:LOCALAPPDATA "HHGodotAgent\tooling\godot-4.7.1-stable\bin\Godot_v4.7.1-stable_win64.exe"
$ev = Join-Path $prod ".evidence\VF6WP5-10-trace"
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
$map = $args[0]
if (-not $map) { throw "map required" }
$log = Join-Path $ev ("trace_" + $map + ".log")
$env:HH_VF_DIAG_MAP = $map
$code = [HhGodotHost.Runner]::Run($godot, "--path `"$prod`" --headless --script res://tests/diag_trace_map.gd", $prod, $log, ($log + ".err"), $true)
Remove-Item Env:HH_VF_DIAG_MAP -ErrorAction SilentlyContinue
Write-Output "TRACE_EXIT=$code map=$map"
exit $code
