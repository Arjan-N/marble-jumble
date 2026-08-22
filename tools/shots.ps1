<#
.SYNOPSIS
  Render one still per section of a course, for looking at.

.DESCRIPTION
  Issue #3 is a presentation problem, and presentation problems are not
  answerable by reading constants — you have to see the frame. This drives
  tools/course_shot.gd once per station in tools/course_shot.gd's STATIONS and
  leaves a numbered PNG per section in -Out.

  Each station is a separate engine run on purpose; see the header comment in
  course_shot.gd for why a single sweep could not be trusted.

  Movie mode needs a window, so this cannot run --headless.

.EXAMPLE
  tools\shots.ps1
  tools\shots.ps1 -Out C:\tmp\after -Stations 3,4
#>
param(
    # Where the stills land. Wiped first, so point it somewhere disposable.
    [string]$Out = "$env:TEMP\marble-jumble-shots",
    # Which stations to render. Defaults to all seven sections.
    [int[]]$Stations = @(0, 1, 2, 3, 4, 5, 6),
    # Frames recorded per station. Only the last is kept — the earlier ones are
    # the pulsing plume light and anything else animated settling down.
    [int]$Frames = 8
)

$ErrorActionPreference = 'Stop'

$godot = (Get-Command Godot_v4.7.2-stable_win64_console.exe -ErrorAction SilentlyContinue).Source
if (-not $godot) { $godot = (Get-Command godot -ErrorAction SilentlyContinue).Source }
if (-not $godot) { throw "Godot 4 not found on PATH." }

$project = Split-Path $PSScriptRoot -Parent

if (Test-Path $Out) { Remove-Item -Recurse -Force $Out }
New-Item -ItemType Directory -Force $Out | Out-Null

foreach ($station in $Stations) {
    $scratch = Join-Path $Out "raw$station"
    New-Item -ItemType Directory -Force $scratch | Out-Null

    $env:MJ_STATION = "$station"
    $log = & $godot --path $project res://tools/course_shot.tscn `
        --fixed-fps 60 --write-movie (Join-Path $scratch "f.png") --quit-after $Frames 2>&1

    $errors = $log | Select-String "SCRIPT ERROR|Parse Error"
    if ($errors) {
        $errors | Select-Object -First 5 | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        throw "Station $station did not render."
    }

    # The movie writer numbers frames itself; the last one is the settled shot.
    $last = Get-ChildItem $scratch -Filter *.png | Sort-Object Name | Select-Object -Last 1
    if (-not $last) { throw "Station $station wrote no frames." }

    $ratio = ($log | Select-String "ratio ([\d.]+)").Matches[0].Groups[1].Value
    $named = Join-Path $Out ("{0}-ratio{1}.png" -f $station, $ratio)
    Move-Item $last.FullName $named
    Remove-Item -Recurse -Force $scratch

    Write-Host ("  station {0} (ratio {1}) -> {2}" -f $station, $ratio, (Split-Path $named -Leaf))
}

Remove-Item Env:\MJ_STATION -ErrorAction SilentlyContinue
Write-Host "`nStills in $Out"
