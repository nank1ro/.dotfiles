#!/bin/sh
input=$(cat)
printf '%s' "$input" | /usr/bin/grep -Eiq '\b(git|commit)\b' || exit 0
printf '%s' "$input" | /usr/bin/python3 /Users/ale/.claude/hooks/commit-review-gate.py
status=$?
[ "$status" -eq 0 ] && exit 0
printf '%s\n' 'Commit-review hook failed; repair the hook before committing.' >&2
exit 2
