---
name: commit-review
description: Review staged code at the commit boundary using independent native Codex, Claude Code, and OpenCode sessions. Use when preparing a non-trivial commit or when the commit-review gate blocks one. Includes two correctness reviewers, a GLM simplification lane, adjudication, a separate fix worker, one confirmation pass, and staged-content clearance.
---

# Commit review

Use the installed `/Users/ale/.local/bin/agent-review` command. It runs native CLI
sessions using the user's existing subscriptions. Do not replace them with direct
API calls, a proxy, or the parent agent's same-conversation self-review.

Only an actual agent-commit attempt triggers this workflow. Human commits in
Lazygit or a terminal do not trigger AI review. Do not run it after a turn,
on stop, on save, or while the user is iterating. Stage intended files and attempt
the authorized commit with `/Users/ale/.local/bin/agent-commit -m "message"`;
that checked command requests review when appropriate. Never use raw git commit
for agent-made commits.
The review command itself does not commit or push.

1. Stage only the intended files. Verify `git diff --cached --stat`. Write the
   user's requirements/acceptance criteria to a local file if the diff needs
   context. Do not include the implementer's plan or explanation.
2. Run `agent-review start --author fable` from the repository (or `--author astra`
   when Astra implemented; `--author glm` when GLM implemented). Optionally pass
   `--requirements /absolute/path/to/requirements.txt`. The runner freezes the
   staged tree and launches two correctness lanes plus GLM simplification in
   parallel. Normally correctness is Astra and fresh Opus; if Astra authored the
   change, correctness is Fable and fresh Opus. No reviewer edits or delegates.
3. Read each report in the printed review directory. Adjudicate concrete findings.
   In `decisions.json`, mark each finding `fixed` or `rejected` and supply a reason
   backed by evidence. Never reject a finding only to clear the gate. Zero findings
   is valid; do not manufacture work.
4. Send accepted findings to a separate fix worker with an explicit scope, using
   available subagent tools or a new native CLI session. Do not use either reviewer
   as the fixer. Allow only one writer in this worktree. Record the worker's model
   and session/task identifier in `decisions.json`'s `fixer` field. Stage its fixes
   explicitly and run relevant validation. If there are no accepted findings, skip
   this step. GLM is suitable for bounded mechanical fixes; use a stronger worker
   when correctness requires it.
5. Run `agent-review finish /absolute/path/to/review-directory`. Changed staged
   content triggers exactly one confirmation pass restricted to accepted fixes.
   Provider errors, malformed reports, missing dispositions, changed HEAD, stale
   staged content, or failed confirmation do not clear review. If confirmation
   fails, surface the remaining issue; do not rerun a whole review to start a loop.
6. Once cleared, run `agent-commit -m "message"` as a separate shell call when the
   commit is authorized. It preserves existing Git hooks and checks the staged tree
   again after hooks run. No `-a`, pathspecs, or chained staging. Push only within
   the user's authorized scope.

All reports, frozen snapshots, decisions and ledgers live under the worktree's
private Git directory (`git rev-parse --git-path agent-reviews`). They never enter
the tracked source tree. Do not add them to Git. Keep them for local audit.

AI review is scoped to agent-commit. Human CLI and GUI commits use normal Git
hooks and are not intercepted. The checked agent command preserves the repository's
existing hooks and checks clearance again after they run. All agents must use this
command; this is a workflow requirement, not a security boundary against an agent
that deliberately invokes raw Git. Do not use --no-verify or change hooks to bypass.

Run `agent-review check` to verify clearance without committing. An unchanged
snapshot can be reused; any staged-content or HEAD change invalidates clearance.
The classifier skips documentation, lockfiles and routine manifest/config bookkeeping.
Any source/test file, executable or CI configuration, substantive package scripts or
entrypoint changes, or unfamiliar file requires review. Mixed commits are reviewed.
The command refuses to start without a gate request for the current staged snapshot.

Report reviewer models, actionable findings, fixes/rejections and validation. A
successful command exit alone is not evidence that the findings were resolved.
