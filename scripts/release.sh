#!/bin/bash
set -euo pipefail

remote="${REMOTE:-origin}"
branch="${BRANCH:-main}"
repo="jint233/cmd-tab-ultra"
plist="com.stoutput.cmdtabultra.plist"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command git
require_command gh
require_command make
require_command /usr/libexec/PlistBuddy

version=$(/usr/libexec/PlistBuddy -c "Print :Version" "$plist")
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

make clean
make lint
make package

zip_path="dist/CmdTabUltra-universal.zip"
dmg_path="dist/CmdTabUltra-$version.dmg"
pkg_path="dist/CmdTabUltra-$version.pkg"

if [[ ! -f "$zip_path" || ! -f "$dmg_path" || ! -f "$pkg_path" ]]; then
  echo "Expected release assets were not generated." >&2
  exit 1
fi

git tag -a "$tag" -m "Release $tag"
git push "$remote" "$tag"

gh release create "$tag" \
  "$zip_path" \
  "$dmg_path" \
  "$pkg_path" \
  --repo "$repo" \
  --title "CmdTabUltra $version" \
  --notes "Release $tag"

echo "Published $tag to https://github.com/$repo/releases/tag/$tag"
