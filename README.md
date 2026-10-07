# Bollywood Meme Closer — Copilot CLI

A tiny global Copilot CLI hook that adds one relevant Bollywood meme dialogue to the end of an answer.

## Why a hook?

The hook runs on `agentStop`. It locally scores the current transcript against the 101-dialogue corpus. If the match is strong enough, it blocks completion once and sends Copilot a final instruction to append the selected meme.

This is intentionally:
- local — no web call
- deterministic — no extra model call for selection
- global — applies to your Copilot CLI sessions
- self-limiting — never loops because it ignores turns it forced itself
- conservative — skips sensitive topics and weak matches

## Install

Run one line in your terminal:

- **Windows (PowerShell):** `irm https://raw.githubusercontent.com/Mitalee/bollywood-meme-skill/main/install.ps1 | iex`
- **Mac or Linux:** `curl -fsSL https://raw.githubusercontent.com/Mitalee/bollywood-meme-skill/main/install.sh | sh`

It asks once for a name or email so you can rate memes (type `no` to skip). Then open a new terminal window and start Copilot CLI.

Needs Python 3.

## Help improve this skill

After each meme, reply **1** for 👍 or **0** for 👎. Your ratings go to [Tuning Fork](https://github.com/Mitalee/tuning-fork), which the installer sets up for you. To change your name or turn ratings on later, run the installer again.

## What gets installed

```text
~/.copilot/
├── hooks/
│   ├── bollywood-meme.json
│   ├── bollywood_meme_hook.py
│   └── bollywood_memes.json
└── skills/
    └── bollywood-meme-closer/
        └── SKILL.md
```

On Windows the same paths are under `%USERPROFILE%\.copilot\`.

If `COPILOT_HOME` is set, it is used instead.

## Remove it

Delete:

```text
~/.copilot/hooks/bollywood-meme.json
~/.copilot/hooks/bollywood_meme_hook.py
~/.copilot/hooks/bollywood_memes.json
~/.copilot/hooks/bollywood_meme_tuningfork.json   (if you added it)
~/.copilot/skills/bollywood-meme-closer/
```

Then restart Copilot CLI.

## Important behavior

`agentStop` can force another turn but cannot directly rewrite the main response. The hook therefore asks Copilot for one final turn containing the meme. The GitHub hook reference documents this `decision: "block"` + `reason` behavior.

The hook has a 2-second timeout, but normal execution should be much faster because selection is local.

## Tuning

Edit `bollywood_meme_hook.py`:

- `SKIP_TERMS` — topics where memes should never appear
- threshold `1.15` — raise it for fewer memes, lower it for more
- `recent_ids[:10]` — controls repetition suppression

The corpus is `bollywood_memes.json`.

## Test manually

You can test the selector without Copilot by piping a fake `agentStop` payload into the script. A real Copilot transcript path is normally supplied by the CLI.

## Current corpus caveat

The corpus is a curated/programmatically assembled 100-entry reference. Some source fields are search/reference URLs rather than direct image assets. Treat it as a meme-selection corpus, not as a scholarly film-dialogue database.
