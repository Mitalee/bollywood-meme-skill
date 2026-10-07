#!/usr/bin/env bash
set -euo pipefail

COPILOT_HOME="${COPILOT_HOME:-$HOME/.copilot}"
HOOKS="$COPILOT_HOME/hooks"
SKILL="$COPILOT_HOME/skills/bollywood-meme-closer"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOOKS" "$SKILL"
cp "$ROOT/hook/bollywood-meme.json" "$HOOKS/bollywood-meme.json"
cp "$ROOT/hook/bollywood_meme_hook.py" "$HOOKS/bollywood_meme_hook.py"
cp "$ROOT/skill/bollywood_memes.json" "$HOOKS/bollywood_memes.json"
cp "$ROOT/skill/SKILL.md" "$SKILL/SKILL.md"
chmod +x "$HOOKS/bollywood_meme_hook.py"

echo
echo "Installed Bollywood Meme Closer globally for Copilot CLI."
echo "Restart Copilot CLI to load the hook."
