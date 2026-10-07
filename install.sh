#!/bin/sh
# Bollywood Meme Closer installer for GitHub Copilot CLI.
# One line: curl -fsSL https://raw.githubusercontent.com/Mitalee/bollywood-meme-skill/main/install.sh | sh
set -eu

BASE="https://raw.githubusercontent.com/Mitalee/bollywood-meme-skill/main"
COPILOT_HOME="${COPILOT_HOME:-$HOME/.copilot}"
HOOKS="$COPILOT_HOME/hooks"
SKILL="$COPILOT_HOME/skills/bollywood-meme-closer"
mkdir -p "$HOOKS" "$SKILL"

# Use local files when run from a clone, otherwise download them.
ROOT=""
case "$0" in
  */install.sh|install.sh) ROOT="$(cd "$(dirname "$0")" && pwd)" ;;
esac
get() {
  if [ -n "$ROOT" ] && [ -f "$ROOT/$1" ]; then cp "$ROOT/$1" "$2"
  else curl -fsSL "$BASE/$1" -o "$2"; fi
}
get hook/bollywood-meme.json "$HOOKS/bollywood-meme.json"
get hook/bollywood_meme_hook.py "$HOOKS/bollywood_meme_hook.py"
get skill/bollywood_memes.json "$HOOKS/bollywood_memes.json"
get skill/SKILL.md "$SKILL/SKILL.md"
chmod +x "$HOOKS/bollywood_meme_hook.py"
echo "Installed Bollywood Meme Closer for Copilot CLI."

if ! command -v python3 >/dev/null 2>&1; then
  echo "Note: Python 3 isn't installed. Install it so the memes can run."
fi

# Optional: rate memes through Tuning Fork.
CFG="$HOOKS/bollywood_meme_tuningfork.json"
CURRENT=""
if [ -f "$CFG" ]; then
  CURRENT="$(sed -n 's/.*"user_identity"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CFG" | head -n 1)"
fi
if [ -z "$CURRENT" ] && command -v git >/dev/null 2>&1; then
  CURRENT="$(git config user.email 2>/dev/null || true)"
fi
echo
echo "Help improve the memes: after each one you can reply 1 (thumbs up) or 0 (thumbs down)."
ANSWER="no"
if [ -n "${BOLLYWOOD_MEME_IDENTITY:-}" ]; then
  ANSWER="$BOLLYWOOD_MEME_IDENTITY"
elif (: </dev/tty) 2>/dev/null; then
  if [ -n "$CURRENT" ]; then printf "Name or email to log ratings under (Enter = %s, or type no): " "$CURRENT"
  else printf "Name or email to log ratings under (or type no): "; fi
  IFS= read -r ANSWER </dev/tty || ANSWER="no"
  ANSWER="$(printf '%s' "$ANSWER" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [ -z "$ANSWER" ] && ANSWER="$CURRENT"
fi
case "$ANSWER" in
  ""|no|n|skip|NO|No)
    echo "Skipped ratings. Run this installer again any time to turn them on." ;;
  *)
    ESCAPED="$(printf '%s' "$ANSWER" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    printf '{"user_identity":"%s"}' "$ESCAPED" > "$CFG"
    echo "Ratings will be logged as $ANSWER. Setting up Tuning Fork..."
    curl -fsSL https://raw.githubusercontent.com/Mitalee/tuning-fork/main/install.sh | sh ;;
esac
echo
echo "Done. Open a new terminal window and start Copilot CLI to see the memes."