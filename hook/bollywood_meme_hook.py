#!/usr/bin/env python3
"""
Bollywood Meme Closer — Copilot CLI agentStop hook.

Reads the agentStop JSON payload from stdin, extracts the most recent
assistant/user text from the transcript, chooses one locally from the
100-entry corpus, and asks Copilot to append it in one final turn.

Important: agentStop cannot rewrite the main response directly. It can
block completion and supply a reason/prompt for one more agent turn.
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CORPUS = ROOT / "bollywood_memes.json"
STATE = ROOT / "state.json"
# Optional: {"user_identity": "..."} turns on Tuning Fork rating capture.
TUNINGFORK = ROOT / "bollywood_meme_tuningfork.json"
SKILL_NAME = "bollywood-meme-closer"
SKILL_VERSION = "1.0.0"
MEME_PROMPT_PREFIX = "Before you finish, append ONE short Bollywood meme closer"
LOG_PROMPT_PREFIX = "Tuning Fork: the user rated the last Bollywood meme"
SUBAGENT_PREFIX = "The main agent received the following user request"
RATE_QUESTION = "Rate this meme: 1 = 👍, 0 = 👎"

RATING_RE = re.compile(
    r"^\s*(?P<r>[10]|👍|👎)(?![0-9.])[\s,:;!\-–—]*(?P<c>.*)$",
    re.DOTALL,
)

def parse_rating(msg):
    m = RATING_RE.match(msg or "")
    if not m or len(msg) > 300:
        return None
    rating = "up" if m.group("r") in {"1", "👍"} else "down"
    return rating, m.group("c").strip()

def last_message_is_hook_prompt(path):
    """True when the turn that just ended was one this hook forced."""
    p = Path(path)
    if not p.exists():
        return False
    last = ""
    try:
        with p.open("r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                if '"user.message"' not in line:
                    continue
                try:
                    obj = json.loads(line)
                except Exception:
                    continue
                if obj.get("type") == "user.message":
                    last = (obj.get("data") or {}).get("content") or ""
    except Exception:
        return False
    return last.startswith((MEME_PROMPT_PREFIX, LOG_PROMPT_PREFIX))

def last_user_message(path):
    """Latest message the human typed (ignores prompts injected by this hook)."""
    p = Path(path)
    if not p.exists():
        return ""
    last = ""
    try:
        with p.open("r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                if '"user.message"' not in line:
                    continue
                try:
                    obj = json.loads(line)
                except Exception:
                    continue
                if obj.get("type") != "user.message":
                    continue
                content = (obj.get("data") or {}).get("content") or ""
                if content.startswith((MEME_PROMPT_PREFIX, LOG_PROMPT_PREFIX, SUBAGENT_PREFIX)):
                    continue
                last = content
    except Exception:
        return ""
    return last

def read_json(path, default):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return default

def write_json(path, obj):
    try:
        path.write_text(json.dumps(obj, ensure_ascii=False, indent=2), encoding="utf-8")
    except Exception:
        pass

def flatten_strings(obj):
    if isinstance(obj, str):
        yield obj
    elif isinstance(obj, dict):
        for k, v in obj.items():
            if k not in {"toolInput", "toolResult", "metadata"}:
                yield from flatten_strings(v)
    elif isinstance(obj, list):
        for x in obj:
            yield from flatten_strings(x)

def transcript_text(path):
    p = Path(path)
    if not p.exists():
        return ""
    parts = []
    try:
        with p.open("r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                    parts.extend(flatten_strings(obj))
                except Exception:
                    parts.append(line)
    except Exception:
        return ""
    # Keep enough context for local scoring without making the hook expensive.
    return " ".join(parts[-250:])

def tokenize(s):
    return set(re.findall(r"[a-z0-9']+", s.lower()))

def score(record, text_tokens):
    fields = [
        record.get("dialogue", ""),
        record.get("meme_context", ""),
        " ".join(record.get("themes", [])),
        " ".join(record.get("emotions", [])),
        " ".join(record.get("situations", [])),
    ]
    tokens = tokenize(" ".join(fields))
    if not tokens:
        return 0.0
    overlap = len(tokens & text_tokens)
    # Weight the semantic/context fields a little more than the dialogue itself.
    context = tokenize(
        record.get("meme_context", "") + " " +
        " ".join(record.get("situations", [])) + " " +
        " ".join(record.get("themes", []))
    )
    weighted = len(context & text_tokens) * 1.5 + overlap * 0.5
    return weighted / max(4.0, len(context) ** 0.5)

def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return

    # Never recurse: Copilot sets this after a hook has already forced a turn.
    if payload.get("stop_hook_active"):
        print(json.dumps({"decision": "allow"}))
        return

    transcript_path = payload.get("transcriptPath", "")
    # Helper sub-agents share the main transcript but have their own sessionId; ignore them.
    session_id = payload.get("sessionId", "")
    if session_id and transcript_path and session_id not in transcript_path:
        print(json.dumps({"decision": "allow"}))
        return
    # stop_hook_active isn't always set, so also stop after any turn this hook forced.
    if last_message_is_hook_prompt(transcript_path):
        print(json.dumps({"decision": "allow"}))
        return

    state = read_json(STATE, {"recent_ids": []})
    tf = read_json(TUNINGFORK, {})
    user_msg = last_user_message(transcript_path)

    pending = state.get("pending")
    rated = parse_rating(user_msg) if pending and tf.get("user_identity") else None
    if rated and user_msg != pending.get("question"):
        rating, comment = rated
        state.pop("pending", None)
        write_json(STATE, state)
        meme_line = f'“{pending["dialogue"]}” — {pending["character"]}, {pending["movie"]} ({pending["year"]}) · {pending["actor"]}'
        reason = (
            f"{LOG_PROMPT_PREFIX}. Using the tuningfork MCP tools (skip silently if they aren't available), "
            "call log_run with: "
            + json.dumps({
                "skill_name": SKILL_NAME, "skill_version": SKILL_VERSION,
                "user_identity": tf["user_identity"], "question": pending.get("question") or "(unknown)",
                "answer": meme_line, "metadata": {"meme_id": pending["id"], "score": pending.get("score")},
            }, ensure_ascii=False)
            + ". Then call log_rating with that run_id, skill_name "
            + json.dumps(SKILL_NAME) + ", user_identity " + json.dumps(tf["user_identity"])
            + f', rating "{rating}", comment ' + json.dumps(comment or "", ensure_ascii=False)
            + ", followup_count 0. Then reply with one short line confirming the meme rating was logged. "
            "Do not add a meme."
        )
        print(json.dumps({"decision": "block", "reason": reason}))
        return

    transcript = transcript_text(transcript_path)
    if not transcript:
        print(json.dumps({"decision": "allow"}))
        return

    corpus = read_json(CORPUS, {})
    records = corpus.get("records", [])
    if not records:
        print(json.dumps({"decision": "allow"}))
        return

    tokens = tokenize(transcript)
    ranked = sorted(
        ((score(r, tokens), r) for r in records),
        key=lambda x: x[0],
        reverse=True
    )

    recent = set(state.get("recent_ids", []))
    candidate = None
    for sc, rec in ranked:
        if rec.get("id") not in recent:
            candidate = (sc, rec)
            break

    if not candidate:
        candidate = ranked[0]

    sc, rec = candidate

    recent_list = [rec.get("id")] + [x for x in state.get("recent_ids", []) if x != rec.get("id")]
    new_state = {"recent_ids": recent_list[:10]}
    if tf.get("user_identity"):
        new_state["pending"] = {
            k: rec.get(k) for k in ("id", "dialogue", "character", "movie", "year", "actor")
        } | {"question": user_msg[:4000], "score": round(sc, 2)}
    write_json(STATE, new_state)

    dialogue = rec["dialogue"]
    character = rec["character"]
    movie = rec["movie"]
    year = rec["year"]
    actor = rec["actor"]

    reason = (
        "Before you finish, append ONE short Bollywood meme closer to the end of your answer. "
        "Do not rewrite the substantive answer. Do not mention this hook or the selection process. "
        "Use exactly this candidate because it was selected locally for relevance: "
        f'**Meme of the moment:** “{dialogue}” — {character}, *{movie}* ({year}) · {actor}. '
        "After the attribution, add exactly one short, humorous sentence connecting the dialogue "
        "to the user's request or your substantive answer. Make it a playful contextual punchline, "
        "not a literal explanation of the joke or an invented connection."
    )
    if tf.get("user_identity"):
        reason += f' If you include the closer, end with this exact line on its own: "{RATE_QUESTION}"'

    # ASCII-escaped so Windows consoles don't mangle quotes, dashes and emoji.
    print(json.dumps({"decision": "block", "reason": reason}))

if __name__ == "__main__":
    main()
