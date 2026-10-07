# Bollywood Meme Closer installer for GitHub Copilot CLI.
# One line: irm https://raw.githubusercontent.com/Mitalee/bollywood-meme-skill/main/install.ps1 | iex
& {
$ErrorActionPreference = "Stop"
$base = "https://raw.githubusercontent.com/Mitalee/bollywood-meme-skill/main"
$copilotHome = if ($env:COPILOT_HOME) { $env:COPILOT_HOME } else { Join-Path $HOME ".copilot" }
$hooks = Join-Path $copilotHome "hooks"
$skill = Join-Path $copilotHome "skills\bollywood-meme-closer"
New-Item -ItemType Directory -Force -Path $hooks, $skill | Out-Null

# Use local files when run from a clone, otherwise download them.
$root = if ($PSCommandPath) { Split-Path -Parent $PSCommandPath } else { $null }
function Get-PackageFile($rel, $dest) {
    if ($root -and (Test-Path (Join-Path $root $rel))) { Copy-Item (Join-Path $root $rel) $dest -Force }
    else { Invoke-WebRequest -UseBasicParsing "$base/$rel" -OutFile $dest }
}
Get-PackageFile "hook/bollywood-meme.json" (Join-Path $hooks "bollywood-meme.json")
Get-PackageFile "hook/bollywood_meme_hook.py" (Join-Path $hooks "bollywood_meme_hook.py")
Get-PackageFile "skill/bollywood_memes.json" (Join-Path $hooks "bollywood_memes.json")
Get-PackageFile "skill/SKILL.md" (Join-Path $skill "SKILL.md")
Write-Host "Installed Bollywood Meme Closer for Copilot CLI."

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Note: Python isn't installed. Install it from https://www.python.org/downloads/ so the memes can run." -ForegroundColor Yellow
}

# Optional: rate memes through Tuning Fork.
$cfg = Join-Path $hooks "bollywood_meme_tuningfork.json"
$current = $null
if (Test-Path $cfg) { try { $current = (Get-Content $cfg -Raw | ConvertFrom-Json).user_identity } catch {} }
if (-not $current) { try { $current = (git config user.email 2>$null) } catch {} }
Write-Host ""
Write-Host "Help improve the memes: after each one you can reply 1 (thumbs up) or 0 (thumbs down)."
$prompt = if ($current) { "Name or email to log ratings under (Enter = $current, or type no)" } else { "Name or email to log ratings under (or type no)" }
$answer = $null
if ($env:BOLLYWOOD_MEME_IDENTITY) { $answer = $env:BOLLYWOOD_MEME_IDENTITY }
else { try { $answer = Read-Host $prompt } catch {} }
if ($null -eq $answer) { $answer = "no" }
$answer = $answer.Trim()
if (-not $answer) { $answer = $current }
if ($answer -and $answer -notmatch '^(no|n|skip)$') {
    $json = @{ user_identity = $answer } | ConvertTo-Json -Compress
    [IO.File]::WriteAllText($cfg, $json)
    Write-Host "Ratings will be logged as $answer. Setting up Tuning Fork..."
    & ([scriptblock]::Create((Invoke-RestMethod "https://raw.githubusercontent.com/Mitalee/tuning-fork/main/install.ps1")))
} else {
    Write-Host "Skipped ratings. Run this installer again any time to turn them on."
}
Write-Host ""
Write-Host "Done. Open a new terminal window and start Copilot CLI to see the memes."
}
