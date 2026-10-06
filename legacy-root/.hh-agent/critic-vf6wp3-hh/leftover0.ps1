$ErrorActionPreference = "Stop"
$Repo = "d:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\hh-game-studio"
$Work = Join-Path $Repo ".hh-agent\critic-vf6wp3-hh"
$Iso = Join-Path $Work "iso"
$Godot = Join-Path $env:LOCALAPPDATA "HHGodotAgent\tooling\godot-4.7.1-stable\bin\Godot_v4.7.1-stable_win64_console.exe"
$HeadlessEv = Join-Path $Work "evidence\headless"
$WindowEv = Join-Path $Work "evidence\window"
New-Item -ItemType Directory -Force -Path $HeadlessEv, $WindowEv | Out-Null

function Get-GodotLeftover([string]$needle) {
    @(Get-CimInstance Win32_Process | Where-Object {
        $_.CommandLine -and
        $_.CommandLine -match "Godot_v4.7.1" -and
        $_.CommandLine -match [regex]::Escape($needle)
    }).Count
}

function Invoke-GodotIso {
    param(
        [string]$Label,
        [string[]]$GodotArgs,
        [string]$EvidenceDir,
        [string]$OutLog,
        [string]$ErrLog,
        [int]$TimeoutMs
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Godot
    $psi.Arguments = ($GodotArgs -join " ")
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $psi.EnvironmentVariables["HH_VF_EVIDENCE_DIR"] = $EvidenceDir
    $psi.EnvironmentVariables["HH_VF_STAGE_STORE"] = "progress_vf6wp3_hh.json"
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    $started = Get-Date
    [void]$p.Start()
    $outTask = $p.StandardOutput.ReadToEndAsync()
    $errTask = $p.StandardError.ReadToEndAsync()
    $ok = $p.WaitForExit($TimeoutMs)
    $ended = Get-Date
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
    $stdout | Set-Content -Path $OutLog -Encoding utf8
    $stderr | Set-Content -Path $ErrLog -Encoding utf8
    return @{
        Exit = if ($hung) { -1 } else { $p.ExitCode }
        Elapsed = [math]::Round(($ended - $started).TotalSeconds, 1)
        Hung = $hung
        Pid = $p.Id
    }
}

$before = Get-GodotLeftover "critic-vf6wp3-hh"
if ($before -gt 0) {
    "BLOCKED leftover already on critic-vf6wp3-hh leftover=$before" | Set-Content (Join-Path $Work "leftover0.txt") -Encoding utf8
    Write-Output "BLOCKED leftover_hh=$before"
    exit 2
}

$checkLog = Join-Path $Work "check_stage.log"
Push-Location $Iso
python "tests\check_stage.py" *>&1 | Tee-Object -FilePath $checkLog
$checkExit = $LASTEXITCODE
Pop-Location
$afterCheck = Get-GodotLeftover "critic-vf6wp3-hh"
Write-Output "CHECK_EXIT=$checkExit LEFTOVER=$afterCheck"

$h = Invoke-GodotIso -Label "headless" -GodotArgs @(
    "--headless", "--path", "`"$Iso`"", "--script", "res://tests/run_stage.gd"
) -EvidenceDir $HeadlessEv -OutLog (Join-Path $Work "hh-headless.stdout.log") -ErrLog (Join-Path $Work "hh-headless.stderr.log") -TimeoutMs 240000
Start-Sleep -Seconds 2
$afterHeadless = Get-GodotLeftover "critic-vf6wp3-hh"
Write-Output "HEADLESS_EXIT=$($h.Exit) ELAPSED=$($h.Elapsed) LEFTOVER=$afterHeadless HUNG=$($h.Hung) PID=$($h.Pid)"

$w = Invoke-GodotIso -Label "window" -GodotArgs @(
    "--path", "`"$Iso`"", "--script", "res://tests/run_stage.gd"
) -EvidenceDir $WindowEv -OutLog (Join-Path $Work "hh-window.stdout.log") -ErrLog (Join-Path $Work "hh-window.stderr.log") -TimeoutMs 240000
Start-Sleep -Seconds 2
$afterWindow = Get-GodotLeftover "critic-vf6wp3-hh"
$afterProduct = @(Get-CimInstance Win32_Process | Where-Object {
    $_.CommandLine -and $_.CommandLine -match "Godot_v4.7.1" -and $_.CommandLine -match "dogfood\\superfighters" -and $_.CommandLine -notmatch "critic-"
}).Count
Write-Output "WINDOW_EXIT=$($w.Exit) ELAPSED=$($w.Elapsed) LEFTOVER=$afterWindow HUNG=$($w.Hung) PID=$($w.Pid) EXE=console"

$proof = [ordered]@{
    critic = "HH leftover-0 isolated"
    run_id = "VF6WP3-20260901-ASIA-SAIGON-01"
    command_id = "cmd.vf6-wp3.stage-progress.1"
    iso = ".hh-agent/critic-vf6wp3-hh/iso"
    exe = $Godot
    check_exit = $checkExit
    headless_host_exit = $h.Exit
    headless_elapsed_sec = $h.Elapsed
    headless_hung = $h.Hung
    window_host_exit = $w.Exit
    window_elapsed_sec = $w.Elapsed
    window_hung = $w.Hung
    leftover_before = $before
    after_check = $afterCheck
    after_headless = $afterHeadless
    after_window = $afterWindow
    leftover_after_product = $afterProduct
    leftover = $afterWindow
    host = "System.Diagnostics.Process WaitForExit"
    note = "HH leftover-0 on critic-vf6wp3-hh iso only; did not touch II or product path"
}
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Join-Path $Work "leftover_proof.json"), (($proof | ConvertTo-Json) + "`n"), $utf8)
@(
    "critic=HH leftover-0 isolated"
    "run_id=VF6WP3-20260901-ASIA-SAIGON-01"
    "command_id=cmd.vf6-wp3.stage-progress.1"
    "iso=.hh-agent/critic-vf6wp3-hh/iso"
    "CHECK_EXIT=$checkExit"
    "HEADLESS_HOST_EXIT=$($h.Exit)"
    "HEADLESS_ELAPSED=$($h.Elapsed)"
    "WINDOW_HOST_EXIT=$($w.Exit)"
    "WINDOW_ELAPSED=$($w.Elapsed)"
    "HUNG_H=$($h.Hung)"
    "HUNG_W=$($w.Hung)"
    "LEFTOVER_BEFORE=$before"
    "LEFTOVER_AFTER_CHECK=$afterCheck"
    "LEFTOVER_AFTER_HEADLESS=$afterHeadless"
    "LEFTOVER_AFTER_WINDOW=$afterWindow"
    "LEFTOVER=$afterWindow"
) | Set-Content (Join-Path $Work "leftover0.txt") -Encoding utf8
Write-Output "HH_DONE leftover=$afterWindow check=$checkExit headless=$($h.Exit) window=$($w.Exit)"
exit 0
