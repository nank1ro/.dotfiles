#!/usr/bin/env bash
# PreToolUse pre-filter for the commit-review gate. Registered in settings.json.
# Keeps the Python interpreter off the hot path: only pay for it when the payload
# could involve git (whole-word "git"/"commit", so github.com / digit / etc. do
# not match). Case-insensitive so `Git` and aliases like `git ci` still forward.
input=$(cat)

# Fast allow unless the command mentions the word "commit". This means git
# status/add/diff/log/rebase/merge — and every non-git command — exit here in a
# few ms and never start Python. Real `git commit` in any form still contains
# "commit" (incl. `Git commit`, `-am`, `cd repo && git commit`, `FOO=1 git
# commit`) and is gated. TRADEOFF: a commit *alias* whose name lacks "commit"
# (e.g. `git ci`) would NOT be gated — Ale has no such alias (checked 2026-08-25);
# add its literal name to this grep if one is ever created.
printf '%s' "$input" | grep -iqw 'commit' || exit 0

PY="$HOME/.claude/hooks/commit-review-gate.py"   # $HOME, not dirname "$0": robust to symlinked hook dirs
[ -f "$PY" ] || exit 0
PYBIN=$(command -v python3 || echo /usr/bin/python3)

# Run the gate. Crucially, never propagate a Python failure (missing interp,
# bad path -> python's own exit 2, traceback) as a hard block: exit 2 from a
# PreToolUse hook blocks the tool unconditionally. On any non-zero rc we fail
# OPEN (exit 0, no output) so a broken gate can never brick every commit.
out=$(printf '%s' "$input" | "$PYBIN" "$PY" 2>/dev/null)
rc=$?
[ "$rc" -eq 0 ] || exit 0
[ -n "$out" ] && printf '%s\n' "$out"
exit 0
