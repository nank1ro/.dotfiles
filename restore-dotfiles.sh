#!/bin/bash

# Restore dotfiles from this repo back to their live locations.
# Inverse of sync-dotfiles.sh (which copies live -> repo).
#
# Diff-aware: a file that already matches the repo is left untouched, so a run
# where everything is in sync writes nothing and reports "already matches".
# Only files whose content actually differs are overwritten.
#
# Usage:
#   ./restore-dotfiles.sh            # copy repo -> live (only what differs)
#   ./restore-dotfiles.sh --dry-run  # show what would change, write nothing

REPO_ROOT="$(cd "$(dirname "$0")" && pwd -P)" || exit 1

DRY_RUN=false
if [ "$1" = "--dry-run" ] || [ "$1" = "-n" ]; then
  DRY_RUN=true
  echo "— DRY RUN: no files will be written —"
fi

DIFFS=0        # count of files that differ (would change / did change)
FAILED=false   # set if any write fails

# Restore one file from the repo to its live location, only if content differs.
# Creates the destination's parent dir. Reports unchanged / create / update / FAIL.
restore_file() {
  local src="$1" dest="$2"
  if [ ! -f "$src" ]; then
    echo "⚠ skip     $dest — not in repo ($src)"
    return
  fi
  if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
    echo "= match    $dest"
    return
  fi
  local verb="update"
  [ -f "$dest" ] || verb="create"
  DIFFS=$((DIFFS + 1))
  if [ "$DRY_RUN" = true ]; then
    echo "~ would $verb $dest"
    return
  fi
  if ! mkdir -p "$(dirname "$dest")" || ! cp "$src" "$dest"; then
    echo "✗ FAILED   $dest"
    FAILED=true
    return
  fi
  echo "✓ $verb   $dest"
}

# nvim: directory tree. Detection and write are a SINGLE rsync call so they can
# never disagree: -a applies symlinks/perms too, --checksum compares by content
# (not size+mtime), -i itemizes what changed. rsync's exit code is captured
# directly (no pipe) so a real failure can't be mistaken for "nothing to do".
# WITHOUT --delete, so live plugins / lazy-lock.json are never wiped.
# (This nvim config is deprecated per README — restored for completeness only.)
# NOTE: macOS ships openrsync, which does not itemize symlink-only changes, so a
# diff that is purely a changed symlink won't be counted/previewed here (the real
# -a write still applies it). The tracked nvim tree currently has no symlinks.
restore_nvim() {
  local src="$REPO_ROOT/nvim/" dest="$HOME/.config/nvim/"
  if [ ! -d "$src" ]; then
    echo "⚠ skip     $dest — not in repo ($src)"
    return
  fi
  local flags=(-a --checksum -i --exclude='.git' --exclude='.DS_Store' --exclude='lazy-lock.json')
  if [ "$DRY_RUN" = true ]; then
    flags=(-n "${flags[@]}")
  else
    mkdir -p "$dest"
  fi
  local out rc
  out="$(rsync "${flags[@]}" "$src" "$dest")"  # stderr flows to terminal on error
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "✗ FAILED   $dest (rsync exit $rc)"
    FAILED=true
    return
  fi
  local changes
  changes="$(printf '%s\n' "$out" | grep -E '^[<>c]' || true)"
  if [ -z "$changes" ]; then
    echo "= match    $dest"
    return
  fi
  DIFFS=$((DIFFS + 1))
  local n
  n="$(printf '%s\n' "$changes" | grep -c .)"
  if [ "$DRY_RUN" = true ]; then
    echo "~ would update $dest ($n item(s))"
  else
    echo "✓ update   $dest ($n item(s))"
  fi
}

# Arm this clone's git hooks. Git never clones .git/hooks/, so point core.hooksPath
# at the repo's tracked hooks/ dir. Absolute path => works no matter the CWD at commit
# time (a relative core.hooksPath is resolved against the CWD, which is a footgun).
# Also ensures the hook is executable, since git silently ignores a non-executable
# hook (the commit just succeeds with a hint) — a stripped bit would disable syncing.
arm_hooks() {
  local hook="$REPO_ROOT/hooks/pre-commit"
  if [ ! -f "$hook" ]; then
    echo "⚠ skip     git hooks — $hook not in repo"
    return
  fi
  local want="$REPO_ROOT/hooks" have
  have="$(git -C "$REPO_ROOT" config --local core.hooksPath 2>/dev/null || true)"
  if [ "$have" = "$want" ] && [ -x "$hook" ]; then
    echo "= match    git hooks (core.hooksPath -> hooks/)"
    return
  fi
  DIFFS=$((DIFFS + 1))
  if [ "$DRY_RUN" = true ]; then
    echo "~ would arm git hooks (core.hooksPath -> hooks/)"
    return
  fi
  if chmod +x "$hook" && git -C "$REPO_ROOT" config core.hooksPath "$want"; then
    echo "✓ armed    git hooks (core.hooksPath -> hooks/)"
  else
    echo "✗ FAILED   git hooks (core.hooksPath)"
    FAILED=true
  fi
}

restore_nvim

# lazygit: repo stores config.yaml, but the live file is config.yml.
restore_file "$REPO_ROOT/lazygit/config.yaml" "$HOME/Library/Application Support/lazygit/config.yml"

# lazycommit
restore_file "$REPO_ROOT/.lazycommit.yaml" "$HOME/.config/.lazycommit.yaml"
restore_file "$REPO_ROOT/.lazycommit.prompts.yaml" "$HOME/.config/.lazycommit.prompts.yaml"

# tmux
restore_file "$REPO_ROOT/.tmux.conf" "$HOME/.tmux.conf"

# claude
restore_file "$REPO_ROOT/claude/settings.json" "$HOME/.claude/settings.json"
restore_file "$REPO_ROOT/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# wezterm
restore_file "$REPO_ROOT/.wezterm.lua" "$HOME/.wezterm.lua"

# zshrc
restore_file "$REPO_ROOT/.zshrc" "$HOME/.zshrc"

# ghostty
restore_file "$REPO_ROOT/ghostty/config" "$HOME/.config/ghostty/config"

# finicky (Helium air-traffic-control link routing)
restore_file "$REPO_ROOT/finicky/finicky.js" "$HOME/.config/finicky/finicky.js"

# gitconfig
restore_file "$REPO_ROOT/.gitconfig" "$HOME/.gitconfig"

# git hooks: arm the tracked pre-commit hook on this clone (git never clones .git/hooks/)
arm_hooks

echo
if [ "$FAILED" = true ]; then
  echo "✗ Some restores failed (see above)."
  exit 1
elif [ "$DIFFS" -eq 0 ]; then
  echo "✓ Everything already matches — nothing to restore."
elif [ "$DRY_RUN" = true ]; then
  echo "$DIFFS item(s) would change. Re-run without --dry-run to apply."
else
  echo "✓ Restored $DIFFS item(s)."
fi
