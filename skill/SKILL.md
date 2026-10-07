---
name: bollywood-meme-closer
description: After the normal answer, optionally append one highly relevant Bollywood meme or dialogue from the local bollywood_memes.json corpus. Use when closing out a response with a light Bollywood touch.
---

# Bollywood Meme Closer — Fast Runtime Skill

## Goal
After the normal assistant answer, optionally append ONE highly relevant Bollywood meme/dialogue from the local `bollywood_memes.json` corpus.

## Hard runtime constraints
- NEVER browse the web.
- NEVER load the full corpus into the prompt.
- Retrieve top 5 candidates from the local/embedded index.
- Perform at most one lightweight reranking call.
- Prefer <500 ms added latency.
- If retrieval fails or no candidate clears the threshold, output nothing.

## Input
- `user_query`
- `assistant_response`
- local meme index
- `recent_meme_ids`

## Retrieval
Create a tiny semantic query from:
- situation
- emotion
- intent
- topic
- humor opportunity

Search the local corpus on `meme_context`, `themes`, `emotions`, `situations`, and dialogue.

Return max 5 candidates.

## Rerank
Score candidates:
- contextual fit: 40%
- meme recognizability: 25%
- humor/punch: 20%
- emotional fit: 10%
- novelty: 5%

Return only a meme ID or `NONE`.

Use threshold >= 0.70.

## Repetition
Suppress IDs used in the previous 10 responses. Prefer variety across actor/movie/decade.

## Safety
Do not append humor for grief, self-harm, serious medical emergencies, abuse, serious legal/financial distress, trauma, or similarly sensitive contexts.

## Output
Append at the very end:

**Meme of the moment:** “{dialogue}”  
— {character}, *{movie}* ({year}) · {actor}

If a licensed/direct image URL exists, render/link it. Otherwise omit the image.

Never explain the joke unless needed.

## Source truth
The local corpus is authoritative. Never invent dialogue, attribution, source URLs, or image URLs. Never browse at runtime.

## Data contract
Each record should have:
`id, dialogue, movie, year, actor, character, meme_context, themes[], emotions[], situations[], image_url?, source_url?, confidence?`

## Architecture
User -> normal answer -> semantic retrieval (top 5) -> cheap rerank -> threshold -> append one meme / NONE.

## Tuning Fork evaluation (optional)
Enabled when `~/.copilot/hooks/bollywood_meme_tuningfork.json` exists with `{"user_identity": "<your name or email>"}` and the `tuningfork` MCP server is connected.
- Each meme ends with "Rate this meme: 1 = 👍, 0 = 👎".
- If the user's next message starts with 1 (up) or 0 (down), optionally followed by a comment, the hook asks the agent to call `log_run` (question, meme, meme_id) and `log_rating` (rating + any comment) for skill `bollywood-meme-closer`.
- Unrated memes are not logged.