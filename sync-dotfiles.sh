#!/bin/bash

# Sync all dotfiles from their source locations to this repo

REPO_ROOT="$(dirname "$0")"
cd "$REPO_ROOT" || exit 1

has_changes=false

# Sync nvim config
if [ -d "$HOME/.config/nvim/" ]; then
  rsync -a --delete \
    --exclude='.git' \
    --exclude='.DS_Store' \
    --exclude='lazy-lock.json' \
    "$HOME/.config/nvim/" "$REPO_ROOT/nvim/"

  if [ -n "$(git status --porcelain nvim/)" ]; then
    echo "✓ Synced nvim config"
    has_changes=true
  fi
else
  echo "⚠ Skipping nvim: source directory not found"
fi

# Sync lazygit config
if [ -f "$HOME/Library/Application Support/lazygit/config.yml" ]; then
  mkdir -p "$REPO_ROOT/lazygit"
  cp "$HOME/Library/Application Support/lazygit/config.yml" "$REPO_ROOT/lazygit/config.yaml"

  if [ -n "$(git status --porcelain lazygit/)" ]; then
    echo "✓ Synced lazygit config"
    has_changes=true
  fi
else
  echo "⚠ Skipping lazygit: source file not found"
fi

# Sync wezterm config
if [ -f "$HOME/.wezterm.lua" ]; then
  cp "$HOME/.wezterm.lua" "$REPO_ROOT/.wezterm.lua"

  if [ -n "$(git status --porcelain .wezterm.lua)" ]; then
    echo "✓ Synced wezterm config"
    has_changes=true
  fi
else
  echo "⚠ Skipping wezterm: source file not found"
fi

if [ "$has_changes" = false ]; then
  echo "✓ All configs already up to date"
fi
