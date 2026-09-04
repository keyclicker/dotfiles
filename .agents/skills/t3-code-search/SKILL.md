---
name: t3-code-search
description: Search local T3 Code conversation history by message text and retrieve matching threads. Use when asked to find, recall, or summarize prior T3 Code conversations.
---

# T3 Code search

Query `/var/lib/t3/userdata/state.sqlite` directly. Do not start with Codex
session files, provider logs, browser search, or filesystem-wide scans.

`sqlite3` may be absent. Find matching threads with:

```sh
nix shell nixpkgs#sqlite -c sqlite3 -readonly -header -column \
  /var/lib/t3/userdata/state.sqlite "
SELECT DISTINCT t.thread_id, t.title, t.updated_at
FROM projection_threads t
JOIN projection_thread_messages m USING (thread_id)
WHERE lower(m.text) LIKE '%search term%'
ORDER BY t.updated_at DESC;"
```

Use several `LIKE` clauses for concepts or pipe normalized rows into `rg` for
regex searches. Keep thread IDs beside matches.

```sh
nix shell nixpkgs#sqlite -c sqlite3 -readonly -separator $'\t' \
  /var/lib/t3/userdata/state.sqlite "
SELECT thread_id, role, replace(text, char(10), ' ')
FROM projection_thread_messages;" |
  rg -i 'term one|term two'
```

Read a matched conversation in order:

```sh
nix shell nixpkgs#sqlite -c sqlite3 -readonly -header -column \
  /var/lib/t3/userdata/state.sqlite "
SELECT created_at, role, text
FROM projection_thread_messages
WHERE thread_id = 'THREAD_ID'
ORDER BY created_at;"
```

Return title, concise finding, and `/threads/<thread_id>` link.
