# Bollywood Meme Closer — downloadable package

## Contents
- `SKILL.md` — copy/paste harness skill specification.
- `bollywood_memes.json` — structured 100-entry runtime corpus.
- `bollywood_memes.md` — human-readable reference.
- `README.md` — integration notes.

## Fast runtime design
Do the expensive work offline. Runtime should:
1. embed/query the user situation;
2. retrieve top 5 local records;
3. run one tiny reranker;
4. append one meme only if score >= 0.70;
5. never browse.

## Using this in ChatGPT
This chat cannot install an arbitrary custom skill into the ChatGPT product's internal skill registry from a downloadable zip. However, the `SKILL.md` is written so it can be used as the instruction/spec for a custom harness, agent, or custom GPT-style setup.

For this conversation, I can also follow the same behavior manually: when appropriate, I can select one meme from this corpus and append it to my responses.

## Image URLs
The package uses image-search page URLs rather than direct copyrighted image hotlinks. Replace them with direct/licensed assets if your application has the rights and storage for them.

## Research
The corpus was seeded from established meme/dialogue references, including Indian Meme Templates, India Today, LatestLY, Times of India, IBTimes, Reddit discussion, and meme-template collections. The full research source list is in the JSON and Markdown.
