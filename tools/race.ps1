<#
.SYNOPSIS
  Run headless races and report how long they take.

.DESCRIPTION
  Races are seeded randomly, so one run tells you very little — the spread
  between the fastest and slowest run of the same build is routinely 6 seconds.
  This runs a batch and reports the spread alongside the average.

  The speed comes from --fixed-fps. Without it the engine paces itself against
  the wall clock even headless, and measuring a 28-second race costs 28 seconds.
  With it, each iteration advances a fixed 1/60s as fast as the CPU allows and
  the same race takes well under a second.

.EXAMPLE
  tools\race.ps1
  tools\race.ps1 -Runs 10 -Frames 6000
#>
param(
    # How many races to run. Six is enough to see the spread; more if you are
    # comparing two builds that land within a couple of seconds of each other.
    [int]$Runs = 6,
    # Iterations before the engine quits, at 60 per simulated second. The
    # default is 80 seconds of race — long enough that a course which hangs
    # proves it rather than just looking slow.
    [int]$Frames = 4800,
    # Print each race's trace instead of just the summary.
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'

$godot = (Get-Command Godot_v4.7.2-stable_win64_console.exe -ErrorAction SilentlyContinue).Source
if (-not $godot) { $godot = (Get-Command godot -ErrorAction SilentlyContinue).Source }
if (-not $godot) { throw "Godot 4 not found on PATH." }

$project = Split-Path $PSScriptRoot -Parent
$times = @()
$hung = 0

foreach ($i in 1..$Runs) {
    $out = & $godot --path $project --headless --fixed-fps 60 --disable-render-loop --quit-after $Frames 2>&1

    $errors = $out | Select-String "SCRIPT ERROR|Parse Error"
    if ($errors) {
        $errors | Select-Object -First 5 | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        throw "Run $i did not get as far as a race."
    }

    if ($Verbose) { $out | Select-String "^t=" | ForEach-Object { Write-Host $_ } }

    $done = $out | Select-String "Race complete in ([\d.]+)s"
    if ($done) {
        $times += [double]$done.Matches[0].Groups[1].Value
        Write-Host ("  {0,2}. {1}" -f $i, (($out | Select-String "Race complete") -replace "\s+", " "))
    } else {
        # No completion line means marbles were still RACING when the engine
        # quit — a stall, which is the failure this batch exists to catch.
        $hung++
        Write-Host ("  {0,2}. NEVER FINISHED within {1}s of race" -f $i, ($Frames / 60)) -ForegroundColor Yellow
    }
}

if ($times.Count -gt 0) {
    $s = $times | Measure-Object -Average -Minimum -Maximum
    Write-Host ("`n{0}/{1} finished | avg {2:N1}s | {3:N1}-{4:N1}s" -f `
        $times.Count, $Runs, $s.Average, $s.Minimum, $s.Maximum)
    # DECISIONS.md, 2026-08-20: 20-30 seconds per course.
    if ($s.Minimum -ge 20 -and $s.Maximum -le 30) {
        Write-Host "Every race inside the 20-30s target." -ForegroundColor Green
    } else {
        Write-Host "Outside the 20-30s target." -ForegroundColor Yellow
    }
}
if ($hung -gt 0) { Write-Host "$hung race(s) hung." -ForegroundColor Red }
