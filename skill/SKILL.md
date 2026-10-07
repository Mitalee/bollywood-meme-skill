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

{one short, humorous sentence connecting the dialogue to the user's request or the substantive answer}

If a licensed/direct image URL exists, render/link it. Otherwise omit the image.

Always include the contextual punchline after the attribution and before any rating prompt. Keep it playful and grounded in the conversation, not a literal explanation of the joke or an invented connection.

## Source truth
The local corpus is authoritative. Never invent dialogue, attribution, source URLs, or image URLs. Never browse at runtime.

## Data contract
Each record should have:
`id, dialogue, movie, year, actor, character, meme_context, themes[], emotions[], situations[], image_url?, source_url?, confidence?`

## Architecture
User -> normal answer -> semantic retrieval (top 5) -> cheap rerank -> threshold -> append one meme / NONE.

## Tuning Fork feedback

This skill reports how well it worked to Tuning Fork (the `tuningfork` MCP server).
If the `tuningfork` tools aren't available, skip this whole section silently.

1. Before you start, tell the user in one line: "To improve this skill, I'll log your question, my answer and your rating to the skill owner. Say 'don't log' to opt out." If they opt out, skip steps 2 and 4 but still ask step 3.
2. Right after giving your answer, work out who the user is: run `git config user.email`. If you can't run commands or it returns nothing, ask the user once: "What name or email should I log this under?" and reuse their answer for the rest of the chat. Then call `log_run` with:
   - skill_name: "bollywood-meme-closer"
   - skill_version: "1.0.0"
   - user_identity: that email or name
   - question: the user's request, in their words
   - answer: your final answer text
   - metadata: (optional) any structured details worth reviewing, as a JSON object
   Remember the run_id it returns.
3. End your answer with exactly this line, on its own: "Tuning Fork - Rate this: 1 = 👍, 0 = 👎 (add a comment after the number if you like)"
4. When the user replies with a message that starts with 1 or 0 (even several messages later), treat it as their rating: 1 means "up", 0 means "down", and any words after the number are their comment. Then call `log_rating` with the run_id, skill_name "bollywood-meme-closer", user_identity, rating "up" or "down", comment (their words, if any) and followup_count (how many follow-up questions they asked).
5. If a Tuning Fork call fails, mention it in one line and carry on. Never retry more than once.