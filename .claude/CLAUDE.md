## Tooling preferences

Lean on built-in tools, but reach for the shell when it's genuinely more powerful.

Prefer specialized tools over bash when they do the job better:
- LSP plugins over raw text search for code navigation
- context7 MCP over web search for library/framework docs
- MCPs and LSP plugins where they fit

When working with an unfamiliar library or API, consider fetching up-to-date docs rather than relying on memory.

## Subagents

Reach for subagents when they help — no need to force it:
- Parallel, independent tasks
- Subtasks that don't need this chat's history (keeps context lean)
- Simple, well-scoped work that a cheaper model (Sonnet, Haiku) can handle

## Commits & comments

Do not add Claude/Anthropic trademarks (e.g. "Co-Authored-By: Claude", "Generated with Claude Code") to commit messages, PR descriptions, or code comments unless the user explicitly asks for it.

Git commits are GPG-signed, and signing needs access to `~/.gnupg` which the sandbox blocks. Run `git commit` (and `--amend`) with the sandbox disabled, otherwise it fails with "gpg: signing failed: No secret key".

## Upkeep

Update memory and the local CLAUDE.md when something's worth persisting.
Use skills when one fits the task.
