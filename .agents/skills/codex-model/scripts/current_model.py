#!/usr/bin/env python3
"""Read the current Codex session's latest model selection."""

import json
import os
from pathlib import Path
import sys
from uuid import UUID


def current_model():
    thread_id = os.environ.get("CODEX_THREAD_ID") or os.environ.get("CODEX_SESSION_ID")
    if not thread_id:
        raise ValueError("CODEX_THREAD_ID and CODEX_SESSION_ID are unset")
    # Validate before using an environment value in a glob.
    thread_id = str(UUID(thread_id))
    codex_home = Path(os.environ.get("CODEX_HOME") or Path.home() / ".codex")
    paths = list((codex_home / "sessions").glob(f"*/*/*/rollout-*-{thread_id}.jsonl"))
    if len(paths) != 1:
        raise ValueError(f"expected one matching session log, found {len(paths)}")

    path = paths[0]
    latest = None
    with path.open() as log:
        for line_number, line in enumerate(log, 1):
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                # The running session may still be appending its final line.
                if not line.endswith("\n"):
                    break
                raise ValueError(f"invalid JSON at session line {line_number}") from None
            if record.get("type") == "turn_context":
                latest = (line_number, record["payload"])

    if latest is None:
        raise ValueError("session has no turn_context")
    line_number, context = latest
    model = context.get("model")
    if not isinstance(model, str) or not model.strip():
        raise ValueError("latest turn_context has no model")
    return {
        "model": model,
        "reasoning_effort": context.get("effort"),
        "source": str(path),
        "line": line_number,
    }


if __name__ == "__main__":
    try:
        print(json.dumps(current_model()))
    except (OSError, ValueError, KeyError, TypeError, AttributeError) as error:
        print(f"Cannot verify active Codex model: {error}", file=sys.stderr)
        sys.exit(1)
