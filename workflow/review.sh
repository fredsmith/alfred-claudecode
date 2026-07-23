#!/bin/bash
# Alfred "review" action: given a GitHub PR URL or <project>#<n> shorthand
# (and optional prompt), open a terminal, check out the PR branch into a
# worktree under .worktrees/<pr-branch> inside the local clone, and run
# claude there. The main repo's checked-out branch is left untouched.
#
# Usage (as called by Alfred): review.sh "<pr_url_or_shorthand> [prompt...]"

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
    osascript -e "display dialog \"$1\" with title \"Review\" buttons {\"OK\"} default button \"OK\" with icon stop" >/dev/null 2>&1
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

if [[ "$locator" =~ github\.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
    pr_number="${BASH_REMATCH[3]}"
    repo_path="$HOME/src/github.com/$owner/$repo"
    if [ ! -d "$repo_path" ]; then
        err "Repo not found at $repo_path. Clone it first."
    fi
elif [[ "$locator" =~ ^([^#/[:space:]]+)#([0-9]+)$ ]]; then
    name="${BASH_REMATCH[1]}"
    pr_number="${BASH_REMATCH[2]}"
    repo_path="$(find_project_dir "$name")" || exit 1
    repo="$(basename "$repo_path")"
else
    err "Expected a GitHub PR URL or <project>#<n> shorthand. Got: $locator"
fi

title="$repo PR #$pr_number"

# Fish script run inside the new terminal window. Values come in via env vars
# so we don't have to worry about shell-escaping the prompt. On error we drop
# into a login shell so the user can see what went wrong instead of the window
# closing instantly.
read -r -d '' fish_cmd <<'FISH' || true
if not cd "$REVIEW_DIR"
    echo "ERROR: cd $REVIEW_DIR failed"
    exec fish -l
end

echo "Looking up PR #$REVIEW_PR..."
set pr_branch (gh pr view $REVIEW_PR --json headRefName -q .headRefName 2>/dev/null)
if test -z "$pr_branch"
    echo "ERROR: could not determine head branch for PR #$REVIEW_PR"
    exec fish -l
end
set pr_url (gh pr view $REVIEW_PR --json url -q .url 2>/dev/null)

echo "Fetching latest refs from origin (so PR-review diffs use a current base)..."
git fetch --prune origin

set worktree_path ".worktrees/$pr_branch"

git worktree prune

if not test -d "$worktree_path"
    echo "Creating worktree at $worktree_path..."
    if not git worktree add --detach "$worktree_path" HEAD
        echo
        echo "ERROR: git worktree add $worktree_path failed"
        exec fish -l
    end
end

if not cd "$worktree_path"
    echo "ERROR: cd $worktree_path failed"
    exec fish -l
end

echo "Checking out PR #$REVIEW_PR in worktree..."
if not gh pr checkout $REVIEW_PR
    echo
    echo "ERROR: gh pr checkout $REVIEW_PR failed"
    exec fish -l
end

echo
set guidelines "You are reviewing the pull request $pr_url, which is checked out in this git worktree. Your job is to review the code, not change it.

Rules:
- Do not edit, stage, or commit any files in this worktree.
- Deliver all feedback through the GitHub review interface (use `gh` for inline comments, review summaries, and suggested changes) rather than by modifying the working tree.
- Prefer concrete suggested-change blocks over prose when proposing edits.

Do not begin the review yet, and do not restate these rules. Reply with a single brief line to confirm you're ready, then wait for my instructions."

if test -n "$REVIEW_PROMPT"
    set guidelines "$guidelines

$REVIEW_PROMPT"
end

claude "$guidelines"
FISH

if [ -d "/Applications/Ghostty.app" ]; then
    REVIEW_DIR="$repo_path" \
    REVIEW_PR="$pr_number" \
    REVIEW_PROMPT="$prompt" \
    nohup /Applications/Ghostty.app/Contents/MacOS/ghostty \
        --title="$title" \
        --working-directory="$repo_path" \
        -e fish -lic "$fish_cmd" > /dev/null 2>&1 &
else
    # Terminal.app fallback. AppleScript can't easily pass env vars, so we
    # write a tiny launcher script that re-exports them and execs fish.
    launcher="$(mktemp -t alfred-review).sh"
    {
        printf '#!/bin/bash\n'
        printf 'export REVIEW_DIR=%q\n' "$repo_path"
        printf 'export REVIEW_PR=%q\n' "$pr_number"
        printf 'export REVIEW_PROMPT=%q\n' "$prompt"
        printf 'rm -f %q\n' "$launcher"
        printf 'exec /opt/homebrew/bin/fish -lic %q\n' "$fish_cmd"
    } > "$launcher"
    chmod +x "$launcher"
    osascript -e "tell application \"Terminal\" to do script \"bash $launcher\"" >/dev/null
fi
