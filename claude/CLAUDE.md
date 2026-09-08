# Claude Code instructions

@/Users/ale/.agents/AGENTS.md

The referenced user-level collaboration policy governs Fable's use of sub-agents;
apply it unless writing a plan.

That policy defaults independent review to Opus or Sol; use Astra or Fable only
when the user explicitly requests a state-of-the-art-model review.

Use /Users/ale/.local/bin/agent-commit for every agent-made commit. Follow the
commit-review skill only after that command requests review. Human commits through
Lazygit or a terminal use normal Git hooks without the AI review gate.

When a Fable session is invoked as a reviewer (by agent-review, a review prompt, or
a request to review a diff/branch/PR), review the code directly in that session:
read the staged snapshot or diff, run checks, and report findings. Do not orchestrate
subagents, workflows, or nested reviews for that task.
