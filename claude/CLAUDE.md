# CLAUDE.md

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

## 5. Adversarial Review (mandatory gate, all models)

**A code change is NOT done when tests pass.** It is done when: tests pass AND ≥2 adversarial reviewers have reviewed the diff AND accepted findings are applied. Passing your own tests never substitutes for review.

**TRIGGER — before you tell the user a non-trivial code change is done, finished, verified, working, or ready:**
- Launch ≥2 reviewers in parallel on the diff. Give them the diff plus repo read access to verify, but NOT your plan or reasoning. Their only job: find bugs and reasons it does not work. They must not implement.
- You (the implementer) do not review your own change and do not defend it.
- A separate third agent applies accepted findings; the reviewers stay adversarial (never invested in a fix).
- Only then report done — and state that review ran and what it found.

Trivial = docs/comments/formatting/one-line rename with no runtime surface. Everything else is non-trivial. When unsure, review.

**Sub-agent safety:** sub-agents must never run `git stash`, `git reset`, or other destructive/slow commands — parallel agents share the working tree and would trample each other's changes.

**Model roles (Fable 5 only):** if you are Fable 5, always act as an orchestrator — delegate both investigation and implementation to sub-agents (never do the work yourself), setting each sub-agent's model by task effort. This governs *who types*, not *whether review happens* — the review gate above is unconditional for every model.
- Haiku — cheap mechanical work: bulk search, simple edits, formatting.
- Sonnet — standard investigation and mid-tier implementation.
- Opus — heavy reasoning, hard implementation, and adversarial review.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

If you need a paragraph-long comment to justify why the workaround is OK, the code is wrong — fix the code.
