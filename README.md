# dotfiles

My personal dotfiles — a backup of my live config files, kept in sync with two scripts.

## Scripts

### `sync-dotfiles.sh` — back up (live → repo)

Copies my live configs *into* this repo. Run it after changing a config so the repo
reflects my machine:

```sh
./sync-dotfiles.sh
```

The `hooks/pre-commit` hook runs this on every commit, so the repo's copies of the configs
are refreshed as I work. Git never clones `.git/hooks/`, so the hook is **tracked** in
`hooks/` and enabled per-clone by pointing `core.hooksPath` at it — note this makes git use
`hooks/` for *all* hook types instead of `.git/hooks/`. `restore-dotfiles.sh` sets this up
automatically; to enable it by hand:

```sh
git config core.hooksPath "$(git rev-parse --show-toplevel)/hooks"
```

### `restore-dotfiles.sh` — restore (repo → live)

Copies the configs from this repo back *out* to their live locations — e.g. on a new
machine, or after losing a config. It is **diff-aware**: a file that already matches the
repo is left untouched, so a run where everything is in sync writes nothing (and it never
clobbers a newer local edit with a stale repo copy without showing it).

```sh
./restore-dotfiles.sh            # restore only the files that differ
./restore-dotfiles.sh --dry-run  # preview what would change, write nothing
```

nvim is restored *without* `--delete`, so live plugins / `lazy-lock.json` are never wiped.
It also arms this clone's git hooks (points `core.hooksPath` at the tracked `hooks/` dir),
so the sync-on-commit works on a fresh machine. New machine: `git clone …` →
`./restore-dotfiles.sh`.

## Managed configs

| Config | Live location | Repo path |
|--------|---------------|-----------|
| nvim | `~/.config/nvim/` | `nvim/` |
| lazygit | `~/Library/Application Support/lazygit/config.yml` | `lazygit/config.yaml` |
| lazycommit | `~/.config/.lazycommit.yaml`, `~/.config/.lazycommit.prompts.yaml` | `.lazycommit.yaml`, `.lazycommit.prompts.yaml` |
| tmux | `~/.tmux.conf` | `.tmux.conf` |
| claude | `~/.claude/settings.json`, `~/.claude/CLAUDE.md` | `claude/settings.json`, `claude/CLAUDE.md` |
| wezterm | `~/.wezterm.lua` | `.wezterm.lua` |
| zshrc | `~/.zshrc` | `.zshrc` |
| ghostty | `~/.config/ghostty/config` | `ghostty/config` |
| finicky | `~/.config/finicky/finicky.js` | `finicky/finicky.js` |
| gitconfig | `~/.gitconfig` | `.gitconfig` |

> The `nvim` config is deprecated and has been moved to [here](https://github.com/nank1ro/nvim_config).
