#!/bin/bash
# Alfred "review" action: given a GitHub PR URL or <project>#<n> shorthand
# (and optional prompt), start a Claude Code session in a worktree holding the
# PR head and hand it the /review-pr skill. The main checkout is left
# untouched; claude creates the worktree at .claude/worktrees/pr-<n> itself.
#
# Usage (as called by Alfred): review.sh "<pr_url_or_shorthand> [prompt...]"

set -u
DIALOG_TITLE="Review"
# shellcheck source=launch-common.sh
source "$(dirname "$0")/launch-common.sh"

input="${1-}"

# Split input into the locator (first whitespace-separated token) and the
# prompt (remainder).
locator="${input%%[[:space:]]*}"
if [ "$locator" = "$input" ]; then
    prompt=""
else
    prompt="${input#*[[:space:]]}"
fi

if [[ "$locator" =~ github\.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
    pr_number="${BASH_REMATCH[3]}"
    pr_ref="https://github.com/$owner/$repo/pull/$pr_number"
    repo_path="$HOME/src/github.com/$owner/$repo"
    if [ ! -d "$repo_path" ]; then
        err "Repo not found at $repo_path. Clone it first."
    fi
elif [[ "$locator" =~ ^([^#/[:space:]]+)#([0-9]+)$ ]]; then
    name="${BASH_REMATCH[1]}"
    pr_number="${BASH_REMATCH[2]}"
    repo_path="$(find_project_dir "$name")" || exit 1
    repo="$(basename "$repo_path")"
    # Prefer the full URL so the session is linked to the PR in agent view;
    # fall back to the bare number if gh can't resolve it right now.
    pr_ref="$(cd "$repo_path" && gh pr view "$pr_number" --json url -q .url 2>/dev/null)"
    [ -n "$pr_ref" ] || pr_ref="#$pr_number"
else
    err "Expected a GitHub PR URL or <project>#<n> shorthand. Got: $locator"
fi

require_skill review-pr

title="$repo PR #$pr_number"
initial_prompt="/review-pr $pr_ref"
if [ -n "$prompt" ]; then
    initial_prompt="$initial_prompt $prompt"
fi

launch_claude "$repo_path" "$title" "#$pr_number" "$initial_prompt"
