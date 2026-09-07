---
name: implement-issue
description: Implement a GitHub issue end to end on its own branch, open a draft PR, and self-review it.
argument-hint: <issue-url-or-#number> [extra instructions]
disable-model-invocation: true
allowed-tools: Bash(gh issue view:*), Bash(gh repo view:*), Bash(git status:*), Bash(git branch:*), Bash(git log:*)
---

You are implementing a GitHub issue. The first token of the arguments below is
the issue (a GitHub URL or `#<number>` in this repository). Anything after it
is additional instruction from the user and takes precedence over the issue
text where they conflict.

Arguments: $ARGUMENTS

Steps:
1. Read the issue with `gh issue view <issue> --json url,title,body` and
   restate the goal in one or two lines before starting.
2. Work on a dedicated branch in a git worktree. If this session is already in
   a worktree with a generated branch name (such as `worktree-issue-123`),
   rename the branch to something descriptive that mentions the issue number.
   If this session is in the main checkout, create a worktree and branch first.
3. Implement the change, keeping commits focused.
4. Push the branch and open a draft PR that references the issue.
5. Run /code-review on the PR and address every finding, then report the PR
   URL and what remains open, if anything.
