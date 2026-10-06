$ErrorActionPreference = "Stop"
$Repo = "d:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\hh-game-studio"
$Product = Join-Path $Repo "godot\dogfood\superfighters"
$Godot = Join-Path $env:LOCALAPPDATA "HHGodotAgent\tooling\godot-4.7.1-stable\bin\Godot_v4.7.1-stable_win64_console.exe"
$Work = Join-Path $Repo ".hh-agent\vf6wp1-20260901-04"
$HeadlessEv = Join-Path $Product ".evidence\VF6WP1-20260901-ASIA-SAIGON-04\headless"
$WindowEv = Join-Path $Product ".evidence\VF6WP1-20260901-ASIA-SAIGON-04\window"
$Packed = Join-Path $Product "docs\evidence\VF6WP1-20260901-ASIA-SAIGON-04"
$Review = Join-Path $Product "docs\review\VF6WP1-20260901-ASIA-SAIGON-04"
New-Item -ItemType Directory -Force -Path $Work, $HeadlessEv, $WindowEv | Out-Null

function Get-Leftover {
    @(Get-CimInstance Win32_Process | Where-Object {
        $_.CommandLine -and
        $_.CommandLine -match "dogfood\\superfighters|dogfood/superfighters" -and
        $_.CommandLine -match "Godot_v4.7.1"
    }).Count
}

function Invoke-GodotOfficial {
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
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    $started = Get-Date
    [void]$p.Start()
    $outTask = $p.StandardOutput.ReadToEndAsync()
    $errTask = $p.StandardError.ReadToEndAsync()
    $ok = $p.WaitForExit($TimeoutMs)
    $ended = Get-Date
    if (-not $ok) {
        try { $p.Kill() } catch {}
        Start-Sleep -Seconds 1
        try { $p.WaitForExit(5000) } catch {}
        "TIMEOUT $Label pid=$($p.Id) after $([math]::Round(($ended - $started).TotalSeconds,1))s" | Set-Content -Path $OutLog -Encoding utf8
        return @{
            Exit = -1
            Elapsed = [math]::Round(($ended - $started).TotalSeconds, 1)
            Hung = $true
        }
    }
    $stdout = $outTask.GetAwaiter().GetResult()
    $stderr = $errTask.GetAwaiter().GetResult()
    $stdout | Set-Content -Path $OutLog -Encoding utf8
    $stderr | Set-Content -Path $ErrLog -Encoding utf8
    return @{
        Exit = $p.ExitCode
        Elapsed = [math]::Round(($ended - $started).TotalSeconds, 1)
        Hung = $false
    }
}

if (Get-Leftover -gt 0) {
    Write-Output "BLOCKED leftover Godot already running"
    exit 2
}

$checkLog = Join-Path $Work "check_match.log"
Push-Location $Repo
python "godot\dogfood\superfighters\tests\check_match.py" *>&1 | Tee-Object -FilePath $checkLog
$checkExit = $LASTEXITCODE
Pop-Location
$afterCheck = Get-Leftover
Write-Output "CHECK_EXIT=$checkExit LEFTOVER=$afterCheck"
if ($checkExit -ne 0) { exit 1 }

$h = Invoke-GodotOfficial -Label "headless" -GodotArgs @(
    "--headless", "--path", "`"$Product`"", "--script", "res://tests/run_match.gd"
) -EvidenceDir $HeadlessEv -OutLog (Join-Path $Work "run_match.headless.log") -ErrLog (Join-Path $Work "run_match.headless.err.log") -TimeoutMs 240000
$afterHeadless = Get-Leftover
Write-Output "HEADLESS_EXIT=$($h.Exit) ELAPSED=$($h.Elapsed) LEFTOVER=$afterHeadless HUNG=$($h.Hung)"
if ($h.Exit -ne 0 -or $afterHeadless -ne 0) { exit 1 }

$w = Invoke-GodotOfficial -Label "window" -GodotArgs @(
    "--path", "`"$Product`"", "--script", "res://tests/run_match.gd"
) -EvidenceDir $WindowEv -OutLog (Join-Path $Work "run_match.window.log") -ErrLog (Join-Path $Work "run_match.window.err.log") -TimeoutMs 240000
$afterWindow = Get-Leftover
Write-Output "WINDOW_EXIT=$($w.Exit) ELAPSED=$($w.Elapsed) LEFTOVER=$afterWindow HUNG=$($w.Hung) EXE=console"
if ($w.Exit -ne 0 -or $afterWindow -ne 0 -or $w.Hung) { exit 1 }

$a = Invoke-GodotOfficial -Label "run_all" -GodotArgs @(
    "--headless", "--path", "`"$Product`"", "--script", "res://tests/run_all.gd"
) -EvidenceDir (Join-Path $Work "run_all_ev") -OutLog (Join-Path $Work "run_all.headless.log") -ErrLog (Join-Path $Work "run_all.headless.err.log") -TimeoutMs 2400000
$afterAll = Get-Leftover
Write-Output "RUN_ALL_EXIT=$($a.Exit) ELAPSED=$($a.Elapsed) LEFTOVER=$afterAll HUNG=$($a.Hung)"
if ($a.Exit -ne 0 -or $afterAll -ne 0) { exit 1 }

$leftover = @{
    leftover = $afterAll
    after_check = $afterCheck
    after_headless = $afterHeadless
    after_window = $afterWindow
    after_run_all = $afterAll
    path = "godot/dogfood/superfighters"
    window_exe = $Godot
    window_host_exit = $w.Exit
    window_elapsed_sec = $w.Elapsed
    headless_host_exit = $h.Exit
    headless_elapsed_sec = $h.Elapsed
    run_all_host_exit = $a.Exit
    run_all_elapsed_sec = $a.Elapsed
    host = "System.Diagnostics.Process WaitForExit"
    note = "leftover-0 after each official console-twin process"
}
$exits = @{
    check = $checkExit
    headless = $h.Exit
    window = $w.Exit
    run_all = $a.Exit
    host = "System.Diagnostics.Process.ExitCode"
}
$leftover | ConvertTo-Json | Set-Content (Join-Path $Work "leftover_proof.json") -Encoding utf8
$exits | ConvertTo-Json | Set-Content (Join-Path $Work "exits_proof.json") -Encoding utf8

Write-Output "OFFICIAL_DONE leftover=$afterAll window_sec=$($w.Elapsed) run_all_sec=$($a.Elapsed)"
