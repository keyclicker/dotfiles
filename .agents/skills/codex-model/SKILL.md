---
name: codex-model
description: Look up the active Codex session model locally when answering identity questions or writing model attribution in commits, PRs, and comments.
---

# Codex model

Run the helper before using your model name:

```sh
python3 <skill-directory>/scripts/current_model.py
```

Replace `<skill-directory>` with the directory containing this `SKILL.md`.
The helper uses `CODEX_THREAD_ID` (or `CODEX_SESSION_ID`) to find the session
under `${CODEX_HOME:-~/.codex}/sessions`. It returns JSON with the model ID,
reasoning effort, and the source file and line from the latest `turn_context`.

Use `model` for identity answers. For attribution, format that ID according
to the repository's Git instructions. Rerun the helper for each attribution
operation; do not reuse a result from an earlier turn.

This is a local metadata lookup. Do not browse, load OpenAI Docs, infer the
model from your instructions, or substitute the default in `config.toml`.
If the helper fails, report that the active model could not be verified.
Do not invent an attribution; continue work that does not need it.

Reasoning effort is separate from Fast mode. This helper does not determine
the service tier.
