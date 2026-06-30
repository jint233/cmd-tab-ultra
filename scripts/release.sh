#!/bin/bash
set -euo pipefail

remote="${REMOTE:-origin}"
branch="${BRANCH:-main}"
version_file="VERSION"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command git
require_command gh

if [[ ! -f "$version_file" ]]; then
  echo "Missing $version_file" >&2
  exit 1
fi

version=$(tr -d '[:space:]' < "$version_file")
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid version in $version_file: $version" >&2
  exit 1
fi
tag="v$version"

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated. Run: gh auth login" >&2
  exit 1
fi

current_branch=$(git branch --show-current)
if [[ "$current_branch" != "$branch" ]]; then
  echo "Release must run from $branch. Current branch: $current_branch" >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree is not clean. Commit or stash changes before releasing." >&2
  exit 1
fi

git fetch "$remote" "$branch" --tags

local_head=$(git rev-parse HEAD)
remote_head=$(git rev-parse "$remote/$branch")
if [[ "$local_head" != "$remote_head" ]]; then
  echo "Local HEAD does not match $remote/$branch. Push or pull before releasing." >&2
  exit 1
fi

if git rev-parse "$tag" >/dev/null 2>&1; then
  echo "Tag already exists locally: $tag" >&2
  exit 1
fi

if git ls-remote --exit-code --tags "$remote" "$tag" >/dev/null 2>&1; then
  echo "Tag already exists on remote: $tag" >&2
  exit 1
fi

git tag -a "$tag" -m "Release $tag"
git push "$remote" "$tag"

echo "Pushed $tag. GitHub Actions will build assets and publish the release."
