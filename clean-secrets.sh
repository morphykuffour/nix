#!/bin/bash
set -e

# Suppress git filter-branch warning
export FILTER_BRANCH_SQUELCH_WARNING=1

# Remove the leaked RustDesk key from git history
LEAKED_KEY="sOIwLVZhj6oBdKBD7kaK5YE5+k5EpQWNNMjiAfGkyec="
REPLACEMENT="[REDACTED-RUSTDESK-KEY]"

echo "Starting git history cleanup to remove leaked RustDesk key..."
echo "This will rewrite git history and change all commit hashes!"

# Create a backup branch
echo "Creating backup branch..."
git branch backup-before-secret-cleanup 2>/dev/null || echo "Backup branch already exists"

# Use git filter-branch to rewrite history
echo "Rewriting git history to remove the leaked key..."
git filter-branch --tree-filter '
    for file in $(find . -name "*.nix" -type f 2>/dev/null); do
        if [ -f "$file" ]; then
            sed -i.bak "s/sOIwLVZhj6oBdKBD7kaK5YE5+k5EpQWNNMjiAfGkyec=/[REDACTED-RUSTDESK-KEY]/g" "$file" 2>/dev/null || true
            rm -f "$file.bak" 2>/dev/null || true
        fi
    done
' --all

echo "Cleaning up git filter-branch artifacts..."
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "Git history cleanup completed!"
echo "IMPORTANT: All commit hashes have changed!"
echo "You will need to force push to update the remote repository."
echo "Backup created in branch 'backup-before-secret-cleanup'"