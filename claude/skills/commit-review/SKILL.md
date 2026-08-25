---
name: commit-review
description: Run the mandatory adversarial review at the git commit boundary and clear the commit-review gate. Invoke when the commit-review gate denies a `git commit`, or before committing non-trivial source changes. Runs >=2 adversarial reviewers in parallel on the staged diff, routes accepted findings to a separate fix agent, does a confirm-only pass, writes the review ledger, then clears the gate so a plain `git commit` proceeds.
---

# commit-review

The single, final adversarial review that fires when work is actually complete —
at the `git commit` boundary. This REPLACES per-Stop reviewing. Do not self-trigger
reviews during iterative work; let the user give feedback. Review happens here, once.

## The invariant that makes it converge

The gate allows a commit only when a clearance token matches `sha256(git diff --cached)`.
The token is written by the LAST step below, AFTER every fix is staged. So: reviewers →
fixes staged → confirm-only → **then** clear. Never clear earlier, or the hash won't match
what you commit and you will loop.

Hard cap: **one** full review round + **one** confirm-only pass. Never start a second
fresh hunt. If the confirm pass finds the fixes broke something, surface it to the user —
do not loop.

## Procedure

1. **Stage the final content.** `git add` exactly what you intend to commit. Verify with
   `git diff --cached --stat`. Do NOT plan to commit with `-a`, a pathspec, or a chained
   `git add` — the gate only clears a plain `git commit` of the staged index.

2. **Review — run >=2 adversarial reviewers IN PARALLEL** (one message, concurrent Task
   calls; serial doubles latency). Give each:
   - the staged diff (`git diff --cached`) and read access to the repo to verify;
   - NOT your plan, your reasoning, or each other's output.
   - Their only job: find bugs and concrete reasons the change is wrong or won't work.
     They report findings; **they do not implement**.
   Scope them strictly to the staged diff — no whole-repo rewrites of scope.

3. **Adjudicate + fix.** You (orchestrator) decide which findings are real. Route the
   ACCEPTED findings to a SEPARATE fix agent (not a reviewer, not yourself-as-reviewer).
   If zero findings are accepted, skip to step 5.

4. **Confirm-only pass (skip if step 3 made no edits).** One agent verifies ONLY that the
   applied fixes are correct and complete — it is NOT a new review of the whole diff. If it
   reports the fixes are broken/incomplete, stop and surface to the user. Otherwise continue.

5. **Re-stage + ledger.** `git add` any fix edits. Write the audit ledger to
   `.context/reviews/<utc-timestamp>-<slug>.md` (reviewed paths, findings, and each
   finding's disposition: fixed / rejected-with-reason). Do not stage the ledger into the
   commit unless the repo already tracks `.context/`.

6. **Clear the gate, then commit — as TWO SEPARATE Bash tool calls. Never chain
   them.** The gate evaluates a whole command string *before* it runs, so
   `--clear && git commit` is denied every time (the token isn't written yet when
   the gate inspects the chained commit). Run, as its own call, exactly:
   ```
   python3 ~/.claude/hooks/commit-review-gate.py --clear
   ```
   Then, as a **separate** call, a **plain** `git commit -m "..."` (no `-a`, no
   pathspec, no chained `git add`, nothing before it in the same command).

## Report

Tell the user review ran, how many reviewers, what they found, and what you fixed vs
rejected. "Tests pass" is never a substitute for this review.
