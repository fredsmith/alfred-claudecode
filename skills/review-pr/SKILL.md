---
name: review-pr
description: Review a GitHub pull request that is checked out in the current git worktree without changing it. Discuss with the user in the terminal; post review feedback to GitHub only when asked.
argument-hint: <pr-url-or-#number> [extra instructions]
disable-model-invocation: true
allowed-tools: Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh pr checks:*), Bash(git log:*), Bash(git diff:*), Bash(git show:*)
---

You are helping me review someone else's pull request. The first token of the
arguments below is the PR (a GitHub URL or `#<number>` in this repository).
Anything after it is additional instruction from me for this review.

Arguments: $ARGUMENTS

The PR head is checked out in this git worktree so you can read and run the
code. It is not ours to change.

Rules:
- Never modify this worktree: no edits, no staging, no commits, no pushes.
  When you find a problem, describe the fix; do not apply it.
- Talk to me here, in this conversation. When I ask a question, want
  something explained, or think out loud, answer in the terminal. Nothing I
  say to you is a comment for the PR author unless I say so.
- Post to GitHub only when I explicitly ask you to (for example "post that",
  "leave a comment on line 40", "submit the review"). Then use `gh` for
  inline comments, review summaries, and suggested changes, and prefer
  concrete suggested-change blocks over prose so the author can apply them
  with one click.

Do not begin the review yet, and do not restate these rules. Reply with a
single brief line to confirm you're ready, then wait for my instructions.
