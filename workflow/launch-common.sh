#!/bin/bash
# Shared helpers for the Alfred actions that start a Claude Code session.
# Sourced by review.sh and implement-issue.sh.
#
# Workflow variables consumed here:
#   project_dirs  colon-separated project roots (~ expanded)
#   launch_mode   "window" (default) opens a terminal running claude;
#                 "background" runs `claude --bg` and leaves the session for
#                 `claude agents`.

# Alfred runs scripts with a minimal PATH; make the usual CLI locations visible.
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

FISH="${FISH:-/opt/homebrew/bin/fish}"
[ -x "$FISH" ] || FISH="$(command -v fish || echo /usr/bin/false)"

# err <message> [<dialog title>]: show a blocking error dialog and exit 1.
err() {
    local msg="$1" title="${2:-${DIALOG_TITLE:-Claude Code Launcher}}"
    osascript -e "display dialog \"${msg//\"/\\\"}\" with title \"$title\" buttons {\"OK\"} default button \"OK\" with icon stop" >/dev/null 2>&1
    exit 1
}

notify() {
    local msg="$1" title="$2"
    osascript -e "display notification \"${msg//\"/\\\"}\" with title \"${title//\"/\\\"}\"" >/dev/null 2>&1
}

# Resolve a project name to a local path by scanning project_dirs. Exact
# directory-name match only; ambiguity is an error rather than a guess.
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

# require_skill <name>: the launchers dispatch a slash command, so the matching
# personal skill has to be installed (task install-skills).
require_skill() {
    local skill="$1"
    [ -e "$HOME/.claude/skills/$skill/SKILL.md" ] ||
        err "Skill /$skill is not installed. Run 'task install-skills' in the alfred-claudecode checkout."
}

# launch_claude <dir> <session name> <worktree name or ""> <initial prompt>
#
# Values reach the shell via env vars so we never have to shell-escape the
# prompt. claude sets the terminal title itself from --name; we deliberately do
# not pass --title to Ghostty, because a Ghostty-set title is locked and
# ignores every later title change.
launch_claude() {
    local dir="$1" name="$2" worktree="$3" prompt="$4"
    local mode="${launch_mode:-window}"

    export CLAUDE_LAUNCH_DIR="$dir" CLAUDE_LAUNCH_NAME="$name" \
           CLAUDE_LAUNCH_WORKTREE="$worktree" CLAUDE_LAUNCH_PROMPT="$prompt"

    if [ "$mode" = "background" ]; then
        local out
        if ! out="$("$FISH" -lc '
            cd "$CLAUDE_LAUNCH_DIR"; or exit 1
            set -l wt
            if test -n "$CLAUDE_LAUNCH_WORKTREE"
                set wt --worktree "$CLAUDE_LAUNCH_WORKTREE"
            end
            claude --bg $wt --name "$CLAUDE_LAUNCH_NAME" "$CLAUDE_LAUNCH_PROMPT"' 2>&1)"; then
            err "Could not start background session:

$out"
        fi
        notify "$name" "Claude session started in background"
        return 0
    fi

    # Window mode. On error we drop into a login shell so the user can see what
    # went wrong instead of the window closing instantly.
    local fish_cmd
    read -r -d '' fish_cmd <<'FISH' || true
if not cd "$CLAUDE_LAUNCH_DIR"
    echo "ERROR: cd $CLAUDE_LAUNCH_DIR failed"
    exec fish -l
end
set -l wt
if test -n "$CLAUDE_LAUNCH_WORKTREE"
    set wt --worktree "$CLAUDE_LAUNCH_WORKTREE"
end
if not claude $wt --name "$CLAUDE_LAUNCH_NAME" "$CLAUDE_LAUNCH_PROMPT"
    echo
    echo "ERROR: claude exited with status $status"
    exec fish -l
end
FISH

    if [ -d "/Applications/Ghostty.app" ]; then
        nohup /Applications/Ghostty.app/Contents/MacOS/ghostty \
            --working-directory="$dir" \
            -e "$FISH" -lic "$fish_cmd" > /dev/null 2>&1 &
    else
        # Terminal.app fallback. AppleScript can't easily pass env vars, so we
        # write a tiny launcher script that re-exports them and execs fish.
        local launcher
        launcher="$(mktemp -t alfred-claude).sh"
        {
            printf '#!/bin/bash\n'
            printf 'export CLAUDE_LAUNCH_DIR=%q\n' "$dir"
            printf 'export CLAUDE_LAUNCH_NAME=%q\n' "$name"
            printf 'export CLAUDE_LAUNCH_WORKTREE=%q\n' "$worktree"
            printf 'export CLAUDE_LAUNCH_PROMPT=%q\n' "$prompt"
            printf 'rm -f %q\n' "$launcher"
            printf 'exec %q -lic %q\n' "$FISH" "$fish_cmd"
        } > "$launcher"
        chmod +x "$launcher"
        osascript -e "tell application \"Terminal\"
            activate
            do script \"bash $launcher\"
        end tell" >/dev/null
    fi
}
