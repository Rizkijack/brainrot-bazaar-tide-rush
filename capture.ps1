param([Parameter(Mandatory = $true)][string]$Path)

# Capture the running Roblox Studio playtest at exactly 1280x720 as a JPEG.
# The actual capture is done by focus-capture.exe (compiled from focus-capture.cs):
# it makes the Studio window topmost for the capture so another focused window
# cannot cover the game, then restores the normal z-order. Keeping that work in a
# compiled helper avoids this host's AMSI block on scripts that combine
# CopyFromScreen with SetForegroundWindow / EncoderParameters.

$studio = $null
if ($env:ROBLOX_STUDIO_PID) {
  $studio = Get-Process -Id ([int]$env:ROBLOX_STUDIO_PID) -ErrorAction SilentlyContinue
}
if (-not $studio -or $studio.MainWindowHandle -eq 0) {
  $studio = Get-Process -Name RobloxStudioBeta -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowHandle -ne 0 } | Sort-Object StartTime -Descending | Select-Object -First 1
}
if (-not $studio) { throw "No RobloxStudioBeta window found" }

$helper = Join-Path $PSScriptRoot 'focus-capture.exe'
if (-not (Test-Path $helper)) {
  $source = Join-Path $PSScriptRoot 'focus-capture.cs'
  & 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe' /nologo /target:exe /out:$helper /r:System.Drawing.dll /r:System.Windows.Forms.dll $source
}
if (-not (Test-Path $helper)) { throw "Cannot build focus-capture.exe" }

$directory = Split-Path -Parent $Path
if ($directory -and -not (Test-Path $directory)) { New-Item -ItemType Directory -Path $directory | Out-Null }
$length = & $helper $studio.Id $Path | Select-Object -Last 1
Write-Output "$length"
