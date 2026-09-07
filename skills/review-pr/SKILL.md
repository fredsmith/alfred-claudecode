---
name: review-pr
description: Review a GitHub pull request that is checked out in the current git worktree, delivering all feedback through GitHub instead of editing files.
argument-hint: <pr-url-or-#number> [extra instructions]
disable-model-invocation: true
allowed-tools: Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh pr checks:*), Bash(git log:*), Bash(git diff:*), Bash(git show:*)
---

You are reviewing a pull request. The first token of the arguments below is
the PR (a GitHub URL or `#<number>` in this repository). Anything after it is
additional instruction from the user for this review.

Arguments: $ARGUMENTS

The PR head is checked out in this git worktree. Your job is to review the
code, not change it.

Rules:
- Do not edit, stage, or commit any files in this worktree.
- Deliver all feedback through the GitHub review interface (use `gh` for
  inline comments, review summaries, and suggested changes) rather than by
  modifying the working tree.
- Prefer concrete suggested-change blocks over prose when proposing edits.

Do not begin the review yet, and do not restate these rules. Reply with a
single brief line to confirm you're ready, then wait for my instructions.
