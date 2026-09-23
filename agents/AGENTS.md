# Personal engineering instructions

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

**Watch RED first.** Before writing the fix, run the new test and confirm it fails for the right reason — a test you never saw fail proves nothing.

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Agent collaboration and review

Read applicable repository AGENTS.md instructions and the existing CLAUDE.md
guidance where no AGENTS.md exists. Keep repository build/test commands and domain
conventions in the repository; these personal rules supplement them.

Unless writing a plan, state-of-the-art Astra and Fable sessions lead work by
orchestrating bounded sub-agents to reduce token burn. Use Opus or Sonnet
(Anthropic), Sol or Terra (OpenAI), or GLM 5.3 Flash through OpenCode as workers,
according to the task. The lead owns the outcome and gives each worker a scope,
model, and acceptance criteria. One writer per worktree; use separate worktrees
for parallel implementation. Never stash, reset, or overwrite another agent's
changes.

The lead owns architecture, decisions, and escalations; delegate bounded
implementation, debugging, and testing work to appropriate workers. GLM through
OpenCode remains for small, well-specified chores and easy mechanical tasks:
formatting, release bookkeeping, simple documentation updates, and narrow repetitive
edits. Do not delegate to GLM merely because it is available. Preserve explicit user
choices.

If a GLM chore hits its plan quota or rate limit, stop that worker and hand the same
bounded task to a fresh Opus or Sonnet session, then Sol or Terra if Anthropic is
also limited. Preserve partial changes, acceptance criteria and test results, and
keep one writer. Do not retry a different GLM model against the same exhausted plan.
Reuse known reset information; avoid repeated quota probes.
The lead performs this handoff; ordinary OpenCode sessions are not automatically
transferred between applications by the review runner.

An agent-made Git commit containing review-worthy changes requires one independent
review covering correctness and simplicity. Default to Opus (Anthropic) or Sol
(OpenAI). Use Astra or Fable for review only when the user explicitly requests a
state-of-the-art-model review. GLM is never a reviewer or a substitute for review
clearance. For default review, try the other fresh Opus or Sol reviewer once; leave
review pending only when both are unavailable.
Iterate freely before commit time; do not launch review after every turn. Use the
`commit-review` skill when agent-commit requests it.
Review the exact staged snapshot, provide requirements and repo access, and keep
the implementer's reasoning and other reviewers' reports out of initial reviews.
Reviewers report actionable defects without editing files or delegating reviews.
The lead adjudicates findings; a separate fix worker applies accepted findings.
After fixes, obtain another independent review of the exact staged snapshot. If that
review or its fix confirmation finds a defect, adjudicate it, use a separate fix
worker for accepted findings, and begin a fresh review cycle for the new staged
snapshot. Repeat until the current snapshot receives clearance with no unresolved
findings. Never reuse clearance from an older snapshot or edit a review ledger to
manufacture approval. If both providers are quota- or rate-limited, review remains
pending and may resume after reset for the exact same staged content.

Use `/Users/ale/.local/bin/agent-review` for the shared review workflow and
`/Users/ale/.local/bin/agent-commit` for every agent-made commit across all tools.
Agents must use agent-commit instead of raw git commit. Human commits from Lazygit
or a terminal use the repository's normal Git hooks and do not require AI review.
Stage intended files explicitly before review. Never clear a review merely because
tests passed. Never pass staging options (-a/pathspecs) to the checked commit.
Review ledgers and snapshots are local-only. Never add `.context/reviews` to Git.
Only actual agent-commit attempts trigger this review gate. Documentation, lockfiles,
and routine manifest/config bookkeeping may skip it. Source and tests always require
review, including when mixed with exempt files. Package scripts/entrypoints, substantive
manifest settings, symlinks, executable files, CI workflows and unfamiliar files also
require review. CHANGELOG.md, pubspec.yaml and package.json are examples, not a closed
list; the shared classifier makes the deterministic decision before any model call.

When assigned only to review, confirm fixes, or collect evidence, perform that role
without editing implementation or starting a recursive review workflow.

If a paragraph-long comment is needed to justify a workaround, reconsider the code.

Caveman is an opt-in persona only. When the user explicitly requests it, read
`/Users/ale/.agents/prompts/caveman.md`. Generic requests for brevity do not activate
it. No automatic Caveman hook or plugin is needed.
