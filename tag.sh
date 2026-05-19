#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
METADATA_FILE="$HERE/package/metadata.json"

if [ ! -f "$METADATA_FILE" ]; then
    echo "Error: package/metadata.json not found!" >&2
    exit 1
fi

# Extract version from package/metadata.json
VERSION="$(grep -oE '"Version":[[:space:]]*"[^"]+"' "$METADATA_FILE" | head -1 | sed -E 's/.*"([^"]+)"$/\1/')"
TAG_NAME="v${VERSION}"

echo "Detected Version: ${VERSION}"
echo "Target Tag: ${TAG_NAME}"

# Ensure we're in the git repo root
cd "$HERE"

# 1. Ask to run pack.sh first
if [ -f "$HERE/pack.sh" ]; then
    echo "Packaging .plasmoid..."
    ./pack.sh
fi

# 2. Check if git workspace has uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo ""
    echo "You have uncommitted changes in your workspace."
    read -rp "Do you want to stage and commit them now? [y/N] " stage_and_commit
    if [[ "$stage_and_commit" =~ ^[Yy]$ ]]; then
        read -rp "Enter commit message: " commit_msg
        if [ -z "$commit_msg" ]; then
            commit_msg="feat: release ${TAG_NAME}"
        fi
        git add .
        git commit -m "$commit_msg"
    else
        echo "Please commit your changes first before running this script."
        exit 1
    fi
fi

# 3. Check if tag already exists
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    echo "Warning: Tag ${TAG_NAME} already exists."
    read -rp "Do you want to overwrite/re-create this tag? [y/N] " recreate_tag
    if [[ "$recreate_tag" =~ ^[Yy]$ ]]; then
        git tag -d "$TAG_NAME"
        # Also delete remote tag if it exists (optional/best-effort)
        git push origin --delete "$TAG_NAME" || true
    else
        echo "Aborting."
        exit 0
    fi
fi

# 4. Create local tag
echo "Creating tag ${TAG_NAME}..."
git tag -a "$TAG_NAME" -m "Release ${TAG_NAME}"

# 5. Push current branch and tag
CURRENT_BRANCH="$(git branch --show-current)"
echo "Pushing branch '${CURRENT_BRANCH}' and tag '${TAG_NAME}' to remote..."
git push origin "$CURRENT_BRANCH"
git push origin "$TAG_NAME"

echo ""
echo "=== Success! Version ${VERSION} has been packaged, tagged, and pushed. ==="
