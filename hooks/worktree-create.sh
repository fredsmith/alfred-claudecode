#!/usr/bin/env bash
set -uo pipefail

input=$(cat)
source_dir=$(jq -r '.cwd // empty' <<<"$input")
requested=$(jq -r '.branch_name // .name // empty' <<<"$input")
requested_base=$(jq -r '.base_branch // empty' <<<"$input")

if [[ -z $source_dir ]]; then
  echo "worktree-create: hook input has no cwd" >&2
  exit 1
fi

common_dir=$(git -C "$source_dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || {
  echo "worktree-create: $source_dir is not a git repository" >&2
  exit 1
}
repo_root=$(dirname "$common_dir")

slug=$(printf '%s' "${requested:-agent}" | tr -cs 'A-Za-z0-9._/-' '-' | sed 's|^[./-]*||; s|[./-]*$||')
[[ -n $slug ]] || slug="agent"
git check-ref-format --branch "$slug" >/dev/null 2>&1 || slug="agent-$(date +%s)"

name=$slug
suffix=2
while [[ -e "$repo_root/.worktrees/$name" ]] || git -C "$repo_root" show-ref --verify --quiet "refs/heads/$name"; do
  name="$slug-$suffix"
  ((suffix++))
  if (( suffix > 99 )); then
    echo "worktree-create: no free name for $slug under $repo_root/.worktrees" >&2
    exit 1
  fi
done

ref_exists() {
  git -C "$repo_root" rev-parse --verify --quiet "$1^{commit}" >/dev/null 2>&1
}

# Branch from the freshly-fetched default branch, never from the main checkout's
# HEAD: that checkout is routinely parked on an old or already-merged branch, and
# inheriting it silently bases new work on a dead commit.
resolve_base() {
  if [[ -n $requested_base ]]; then
    ref_exists "$requested_base" && { printf '%s' "$requested_base"; return; }
    echo "worktree-create: requested base $requested_base not found, falling back" >&2
  fi

  if ! git -C "$repo_root" remote get-url origin >/dev/null 2>&1; then
    echo "worktree-create: no origin remote, basing on HEAD" >&2
    printf 'HEAD'
    return
  fi

  git -C "$repo_root" fetch --quiet origin >/dev/null 2>&1 ||
    echo "worktree-create: fetch failed (offline or no access), using cached refs" >&2

  local head_ref
  head_ref=$(git -C "$repo_root" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null) ||
    head_ref=""
  if [[ -z $head_ref ]]; then
    git -C "$repo_root" remote set-head origin --auto >/dev/null 2>&1
    head_ref=$(git -C "$repo_root" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null) ||
      head_ref=""
  fi

  local candidate
  for candidate in "$head_ref" origin/main origin/master; do
    [[ -n $candidate ]] || continue
    ref_exists "$candidate" && { printf '%s' "$candidate"; return; }
  done

  echo "worktree-create: could not resolve origin's default branch, basing on HEAD" >&2
  printf 'HEAD'
}

base=$(resolve_base)

dest="$repo_root/.worktrees/$name"
mkdir -p "$(dirname "$dest")" || exit 1

# --no-track: the branch is not a continuation of the default branch, and an
# upstream of origin/main makes git report it as "ahead of main" and refuse a
# bare push.
if ! git -C "$repo_root" worktree add --no-track -b "$name" "$dest" "$base" >&2; then
  echo "worktree-create: git worktree add failed for $dest (base $base)" >&2
  exit 1
fi

echo "worktree-create: $name based on $base" >&2
printf '%s\n' "$dest"
