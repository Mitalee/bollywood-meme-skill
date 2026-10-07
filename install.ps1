$ErrorActionPreference = "Stop"

$copilotHome = if ($env:COPILOT_HOME) { $env:COPILOT_HOME } else { Join-Path $HOME ".copilot" }
$hooks = Join-Path $copilotHome "hooks"
$skill = Join-Path $copilotHome "skills\bollywood-meme-closer"

New-Item -ItemType Directory -Force -Path $hooks | Out-Null
New-Item -ItemType Directory -Force -Path $skill | Out-Null

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

Copy-Item (Join-Path $root "hook\bollywood-meme.json") (Join-Path $hooks "bollywood-meme.json") -Force
Copy-Item (Join-Path $root "hook\bollywood_meme_hook.py") (Join-Path $hooks "bollywood_meme_hook.py") -Force
Copy-Item (Join-Path $root "skill\bollywood_memes.json") (Join-Path $hooks "bollywood_memes.json") -Force
Copy-Item (Join-Path $root "skill\SKILL.md") (Join-Path $skill "SKILL.md") -Force

Write-Host ""
Write-Host "Installed Bollywood Meme Closer globally for Copilot CLI."
Write-Host "Restart Copilot CLI to load the hook."
Write-Host ""
Write-Host "Files:"
Write-Host "  $hooks\bollywood-meme.json"
Write-Host "  $hooks\bollywood_meme_hook.py"
Write-Host "  $hooks\bollywood_memes.json"
Write-Host "  $skill\SKILL.md"
