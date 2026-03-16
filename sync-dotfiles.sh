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

# Sync lazycommit configs
for lcfile in .lazycommit.yaml .lazycommit.prompts.yaml; do
  if [ -f "$HOME/.config/$lcfile" ]; then
    cp "$HOME/.config/$lcfile" "$REPO_ROOT/$lcfile"

    if [ -n "$(git status --porcelain "$lcfile")" ]; then
      echo "✓ Synced $lcfile"
      has_changes=true
    fi
  else
    echo "⚠ Skipping $lcfile: source file not found"
  fi
done

# Sync tmux config
if [ -f "$HOME/.tmux.conf" ]; then
  cp "$HOME/.tmux.conf" "$REPO_ROOT/.tmux.conf"

  if [ -n "$(git status --porcelain .tmux.conf)" ]; then
    echo "✓ Synced tmux config"
    has_changes=true
  fi
else
  echo "⚠ Skipping tmux: source file not found"
fi

# Sync claude settings
claude_dir="$REPO_ROOT/claude"
mkdir -p "$claude_dir"
for cfile in settings.json CLAUDE.md; do
  if [ -f "$HOME/.claude/$cfile" ]; then
    cp "$HOME/.claude/$cfile" "$claude_dir/$cfile"

    if [ -n "$(git status --porcelain "claude/$cfile")" ]; then
      echo "✓ Synced claude/$cfile"
      has_changes=true
    fi
  else
    echo "⚠ Skipping claude/$cfile: source file not found"
  fi
done

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
