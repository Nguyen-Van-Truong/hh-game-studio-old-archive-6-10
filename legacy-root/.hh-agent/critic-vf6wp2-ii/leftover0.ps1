$ErrorActionPreference = "Stop"
$Repo = "d:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\hh-game-studio"
$Iso = Join-Path $Repo ".hh-agent\critic-vf6wp2-ii\iso"
$Work = Join-Path $Repo ".hh-agent\critic-vf6wp2-ii"
$Ev = Join-Path $Work "window-ev"
$Godot = Join-Path $env:LOCALAPPDATA "HHGodotAgent\tooling\godot-4.7.1-stable\bin\Godot_v4.7.1-stable_win64_console.exe"
New-Item -ItemType Directory -Force -Path $Ev | Out-Null

function Get-IsoLeftover {
    @(Get-CimInstance Win32_Process | Where-Object {
        $_.CommandLine -and
        $_.CommandLine -match "Godot_v4.7.1" -and
        $_.CommandLine -match "critic-vf6wp2-ii"
    }).Count
}

$before = Get-IsoLeftover
if ($before -gt 0) {
    "BLOCKED leftover already on critic-vf6wp2-ii iso=$before" | Set-Content (Join-Path $Work "leftover0.txt") -Encoding utf8
    Write-Output "BLOCKED leftover=$before"
    exit 2
}

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $Godot
$psi.Arguments = "--path `"$Iso`" --script res://tests/run_vs_flow.gd"
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.CreateNoWindow = $true
$psi.EnvironmentVariables["HH_VF_EVIDENCE_DIR"] = $Ev
$p = New-Object System.Diagnostics.Process
$p.StartInfo = $psi
$started = Get-Date
[void]$p.Start()
$outTask = $p.StandardOutput.ReadToEndAsync()
$errTask = $p.StandardError.ReadToEndAsync()
$ok = $p.WaitForExit(240000)
$ended = Get-Date
$elapsed = [math]::Round(($ended - $started).TotalSeconds, 1)
$hung = $false
if (-not $ok) {
    $hung = $true
    try { $p.Kill() } catch {}
    Start-Sleep -Seconds 1
    try { $p.WaitForExit(5000) } catch {}
}
$stdout = ""
$stderr = ""
try { $stdout = $outTask.GetAwaiter().GetResult() } catch {}
try { $stderr = $errTask.GetAwaiter().GetResult() } catch {}
$stdout | Set-Content (Join-Path $Work "critic-ii-window-vs-flow.stdout.log") -Encoding utf8
$stderr | Set-Content (Join-Path $Work "critic-ii-window-vs-flow.stderr.log") -Encoding utf8
$hostExit = if ($hung) { -1 } else { $p.ExitCode }
Start-Sleep -Seconds 2
$after = Get-IsoLeftover
$proof = [ordered]@{
    critic = "II leftover-0 windowed iso"
    run_id = "VF6WP2-20260901-ASIA-SAIGON-02"
    command_id = "cmd.vf6-wp2.vs-flow.2"
    iso = ".hh-agent/critic-vf6wp2-ii/iso"
    exe = $Godot
    window_host_exit = $hostExit
    window_elapsed_sec = $elapsed
    hung = $hung
    leftover_before = $before
    leftover_after = $after
    leftover = $after
    pid = $p.Id
    host = "System.Diagnostics.Process WaitForExit"
}
$proof | ConvertTo-Json | Set-Content (Join-Path $Work "leftover_proof.json") -Encoding utf8
@(
    "critic=II leftover-0 windowed iso"
    "run_id=VF6WP2-20260901-ASIA-SAIGON-02"
    "command_id=cmd.vf6-wp2.vs-flow.2"
    "iso=.hh-agent/critic-vf6wp2-ii/iso"
    "exe=$Godot"
    "WINDOW_HOST_EXIT=$hostExit"
    "ELAPSED_SEC=$elapsed"
    "HUNG=$hung"
    "LEFTOVER_BEFORE=$before"
    "LEFTOVER_AFTER=$after"
) | Set-Content (Join-Path $Work "leftover0.txt") -Encoding utf8
Write-Output "WINDOW_HOST_EXIT=$hostExit ELAPSED=$elapsed HUNG=$hung LEFTOVER=$after"
exit 0
