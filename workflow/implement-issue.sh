#!/bin/bash
# Alfred "implement-issue" action: given a GitHub issue URL or
# [<owner>/]<project>#<n> shorthand (and optional prompt), open a terminal in
# the local clone with the default branch checked out and up to date, then run
# claude primed with the issue text and instructions to branch into a worktree,
# push a draft PR, and self-review it.
#
# Usage (as called by Alfred): implement-issue.sh "<issue_url_or_shorthand> [prompt...]"

set -u

input="${1-}"

# Split input into the locator (first whitespace-separated token) and the
# prompt (remainder).
locator="${input%%[[:space:]]*}"
if [ "$locator" = "$input" ]; then
    prompt=""
else
    prompt="${input#*[[:space:]]}"
fi

err() {
    osascript -e "display dialog \"$1\" with title \"Implement Issue\" buttons {\"OK\"} default button \"OK\" with icon stop" >/dev/null 2>&1
    exit 1
}

# Resolve a project name to a local path by scanning the project_dirs workflow
# variable (colon-separated; ~ expanded). Exact directory-name match only.
find_project_dir() {
    local name="$1"
    local matches=()
    local IFS=:
    local base candidate
    for base in ${project_dirs:-}; do
        base="${base/#\~/$HOME}"
        candidate="$base/$name"
        if [ -d "$candidate" ]; then
            matches+=("$candidate")
        fi
    done
    if [ ${#matches[@]} -eq 0 ]; then
        err "No project named '$name' in project_dirs"
    elif [ ${#matches[@]} -gt 1 ]; then
        err "Multiple projects named '$name': ${matches[*]}"
    fi
    printf '%s\n' "${matches[0]}"
}

if [[ "$locator" =~ github\.com/([^/]+)/([^/]+)/issues/([0-9]+) ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
    issue_number="${BASH_REMATCH[3]}"
    repo_path="$HOME/src/github.com/$owner/$repo"
    if [ ! -d "$repo_path" ]; then
        err "Repo not found at $repo_path. Clone it first."
    fi
elif [[ "$locator" =~ ^([^#[:space:]]+/)?([^#/[:space:]]+)#([0-9]+)$ ]]; then
    name="${BASH_REMATCH[2]}"
    issue_number="${BASH_REMATCH[3]}"
    repo_path="$(find_project_dir "$name")" || exit 1
    repo="$(basename "$repo_path")"
else
    err "Expected a GitHub issue URL or [<owner>/]<project>#<n> shorthand. Got: $locator"
fi

title="$repo issue #$issue_number"

# Fish script run inside the new terminal window. Values come in via env vars
# so we don't have to worry about shell-escaping the prompt. On error we drop
# into a login shell so the user can see what went wrong instead of the window
# closing instantly.
read -r -d '' fish_cmd <<'FISH' || true
if not cd "$IMPL_DIR"
    echo "ERROR: cd $IMPL_DIR failed"
    exec fish -l
end

echo "Looking up issue #$IMPL_ISSUE..."
set issue_url (gh issue view $IMPL_ISSUE --json url -q .url 2>/dev/null | string collect)
if test -z "$issue_url"
    echo "ERROR: could not read issue #$IMPL_ISSUE"
    exec fish -l
end
set issue_title (gh issue view $IMPL_ISSUE --json title -q .title 2>/dev/null | string collect)
set issue_body (gh issue view $IMPL_ISSUE --json body -q .body 2>/dev/null | string collect)

set default_branch (gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null | string collect)
if test -z "$default_branch"
    set default_branch main
end

echo "Fetching latest refs from origin..."
git fetch --prune origin

echo "Switching to $default_branch..."
if not git switch "$default_branch"
    echo
    echo "ERROR: git switch $default_branch failed (uncommitted changes?)"
    exec fish -l
end

if not git merge --ff-only "origin/$default_branch"
    echo
    echo "WARNING: could not fast-forward $default_branch to origin/$default_branch."
    echo "The new branch will start from the local $default_branch instead."
end

echo
set task "You are implementing $issue_url, issue text below.  Create a branch on a worktree for this work.  Push a draft PR, run /code-review and address all issues.
---
$issue_title

$issue_body"

if test -n "$IMPL_PROMPT"
    set task "$task

$IMPL_PROMPT"
end

claude "$task"
FISH

if [ -d "/Applications/Ghostty.app" ]; then
    IMPL_DIR="$repo_path" \
    IMPL_ISSUE="$issue_number" \
    IMPL_PROMPT="$prompt" \
    nohup /Applications/Ghostty.app/Contents/MacOS/ghostty \
        --title="$title" \
        --working-directory="$repo_path" \
        -e fish -lic "$fish_cmd" > /dev/null 2>&1 &
else
    # Terminal.app fallback. AppleScript can't easily pass env vars, so we
    # write a tiny launcher script that re-exports them and execs fish.
    launcher="$(mktemp -t alfred-implement-issue).sh"
    {
        printf '#!/bin/bash\n'
        printf 'export IMPL_DIR=%q\n' "$repo_path"
        printf 'export IMPL_ISSUE=%q\n' "$issue_number"
        printf 'export IMPL_PROMPT=%q\n' "$prompt"
        printf 'rm -f %q\n' "$launcher"
        printf 'exec /opt/homebrew/bin/fish -lic %q\n' "$fish_cmd"
    } > "$launcher"
    chmod +x "$launcher"
    osascript -e "tell application \"Terminal\" to do script \"bash $launcher\"" >/dev/null
fi
