---
name: commit-review
description: Review staged code at agent-commit time with independent Opus or Sol sessions and a fresh cross-provider fallback on usage limits. Covers correctness and simplicity, adjudication, a separate fix worker, one confirmation pass, and staged-content clearance. Human commits and routine bookkeeping are exempt.
---

# Commit review

Use `/Users/ale/.local/bin/agent-review` and the native subscription CLIs. Default
independent review uses Opus or Sol; the runner selects the other provider from the
author when possible, then tries a fresh reviewer from the other default provider.
Astra or Fable review requires an explicit `--reviewer` selection following a user
request. GLM is for chores and easy tasks and is never selected as a reviewer or
used to clear this gate.

Only an actual `agent-commit` attempt triggers this workflow. Human commits in
Lazygit or a terminal use normal Git hooks without AI review. Do not review on save,
on stop, after each turn, or while the user is iterating. The review command itself
does not commit or push.

1. Stage only intended files and inspect `git diff --cached --stat`. Attempt the
   authorized commit with `/Users/ale/.local/bin/agent-commit -m "message"`. Routine
   documentation, lockfiles, known manifest/config bookkeeping and generated files may
   skip review. Generated means: build_runner-style suffixes (`.g.dart`, `.freezed.dart`,
   `.gr.dart`, `.pb.dart`, `.mocks.dart`, ...), files whose header carries a generated-code
   marker, and paths matching globs listed in a repo-root `.agent-review-exempt` file
   (one gitignore-style glob per line, e.g. `curriculum.json`, `*/*/data.json`).
   Any source/test file or substantive/unfamiliar configuration triggers the gate,
   including when mixed with exempt files. Agents must use agent-commit, not raw Git.
2. When blocked, run `agent-review start --author <model>`, using the actual author
   identity: `opus`, `sonnet`, `fable`, `sol`, `terra`, `astra`, or `glm`. Optionally
   pass `--requirements /absolute/path`: include the user's requirements, not the
   implementer's reasoning. The runner freezes the staged tree and obtains one
   independent review covering correctness and simplicity. It defaults to Opus or
   Sol and retries once with the other fresh default reviewer on quota/rate limits.
   Pass `--reviewer astra` or `--reviewer fable` only for an explicitly requested
   state-of-the-art-model review.
3. Read the report and its actual reviewer/attempt history. Adjudicate every finding
   in the printed `decisions.json`: use `fixed` or `rejected`, with evidence. Do not
   manufacture findings or reject them merely to clear the gate.
4. Have a separate fix worker apply accepted findings with an explicit scope and
   one writer per worktree. Record its model and session/task ID in `fixer`. Use an
   appropriate worker; GLM is suitable only for simple mechanical chores. Stage
   accepted fixes explicitly and run relevant validation. Skip this step if no
   findings are accepted.
5. Run `agent-review finish /absolute/path/to/review-directory`. Changed content
   receives at most one confirmation pass restricted to the accepted fixes, using
   the initial reviewer selection and its fallback. If confirmation fails, report
   the issue rather than starting another full review or confirmation loop.
6. Once cleared, run `agent-commit -m "message"` separately when authorized. Existing
   repository hooks still run; the exact staged tree and HEAD are checked after
   hooks. No -a, pathspecs, chained staging, --no-verify, or push without authorization.

A provider's quota/rate error switches to the next reviewer once, using the same
frozen files, prompt and requirements. A completed valid report is required. Both
providers unavailable, authentication failures, malformed reports, unresolved
findings, changed HEAD or stale staged content leave review pending. Fallback is
not triggered by ordinary findings or content refusals. Never substitute GLM.
If both providers are limited during confirmation, it remains pending without
clearance. After limits reset, finish may resume for the exact same staged fixes;
changed fixes are rejected. This does not rerun the initial review.

The runner remembers reviewer limits under `/Users/ale/.agents/state/review-provider-limits`.
It uses a machine-readable reset time when available; otherwise the backoff is one
hour for quota exhaustion and one minute for transient rate limits. These defaults
are retry delays, not claims about the subscription's actual reset. There are no
background retries or automatic purchases/resets. Logs record every attempted or
skipped provider. No paid API-key fallback is introduced.

Snapshots, reports and ledgers live under the worktree's private Git directory
(`git rev-parse --git-path agent-reviews`); never stage them. `agent-review check`
verifies clearance without committing. An unchanged snapshot may reuse clearance;
any staged-tree or HEAD change invalidates it. The start command requires a gate
request for the current staged state.

All agents must use agent-commit. Raw Git remains available for human commits;
this is a workflow requirement, not a security boundary against an agent that
ignores instructions. Reviewers and confirmation workers are read-only, do not
delegate reviews, and do not invoke this workflow recursively.
