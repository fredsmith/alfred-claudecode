#!/bin/bash
# Alfred "implement-issue" action: given a GitHub issue URL or
# [<owner>/]<project>#<n> shorthand (and optional prompt), start a Claude Code
# session in a fresh worktree branched from the repo's default branch and hand
# it the /implement-issue skill. The main checkout is left untouched; claude
# creates the worktree at .claude/worktrees/issue-<n> itself.
#
# Usage (as called by Alfred): implement-issue.sh "<issue_url_or_shorthand> [prompt...]"

set -u
DIALOG_TITLE="Implement Issue"
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

if [[ "$locator" =~ github\.com/([^/]+)/([^/]+)/issues/([0-9]+) ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
    issue_number="${BASH_REMATCH[3]}"
    issue_ref="https://github.com/$owner/$repo/issues/$issue_number"
    repo_path="$HOME/src/github.com/$owner/$repo"
    if [ ! -d "$repo_path" ]; then
        err "Repo not found at $repo_path. Clone it first."
    fi
elif [[ "$locator" =~ ^([^#[:space:]]+/)?([^#/[:space:]]+)#([0-9]+)$ ]]; then
    name="${BASH_REMATCH[2]}"
    issue_number="${BASH_REMATCH[3]}"
    repo_path="$(find_project_dir "$name")" || exit 1
    repo="$(basename "$repo_path")"
    issue_ref="$(cd "$repo_path" && gh issue view "$issue_number" --json url -q .url 2>/dev/null)"
    [ -n "$issue_ref" ] || issue_ref="#$issue_number"
else
    err "Expected a GitHub issue URL or [<owner>/]<project>#<n> shorthand. Got: $locator"
fi

require_skill implement-issue

title="$repo issue #$issue_number"
initial_prompt="/implement-issue $issue_ref"
if [ -n "$prompt" ]; then
    initial_prompt="$initial_prompt $prompt"
fi

launch_claude "$repo_path" "$title" "issue-$issue_number" "$initial_prompt"
