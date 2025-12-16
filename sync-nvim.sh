#!/bin/bash

# Sync nvim config from ~/.config/nvim/ to the dotfiles repo

SOURCE="$HOME/.config/nvim/"
TARGET="$(dirname "$0")/nvim/"

# Check if source directory exists
if [ ! -d "$SOURCE" ]; then
    echo "Error: Source directory $SOURCE does not exist"
    exit 1
fi

# Create target directory if it doesn't exist
mkdir -p "$TARGET"

# Sync the files using rsync
# --archive: archive mode (preserves permissions, timestamps, etc.)
# --delete: delete files in target that don't exist in source
# --exclude: exclude certain files/directories
rsync -a --delete \
    --exclude='.git' \
    --exclude='.DS_Store' \
    --exclude='lazy-lock.json' \
    "$SOURCE" "$TARGET"

# Check if there are changes to commit
if [ -n "$(git -C "$(dirname "$0")" status --porcelain nvim/)" ]; then
    echo "✓ Synced nvim config to dotfiles repo"
    git -C "$(dirname "$0")" add nvim/
else
    echo "✓ nvim config already up to date"
fi
