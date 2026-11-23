# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles. Directories mirror their location under `$HOME` and are wired in by **relative symlinks** pointing back into this repo (cloned directly under `~`; the examples below call it `teru_dots`):

- `~/.config/nvim` → `teru_dots/.config/nvim` (whole directory)
- `~/.oh-my-zsh/custom` → `teru_dots/.oh-my-zsh/custom` (only the `custom/` dir; oh-my-zsh itself is not tracked)
- `~/.config/hypr` → `teru_dots/.config/hypr` (whole directory)
- `~/.config/quickshell` → `teru_dots/.config/quickshell` (whole directory)
- `~/.config/ghostty` → `teru_dots/.config/ghostty` (whole directory; config file is `config.ghostty`)
- `~/.config/matugen` → `teru_dots/.config/matugen` (whole directory)
- `~/.claude/settings.json` and `~/.claude/hooks/notify.sh` → `teru_dots/.claude/...` (file-level links only; `~/.claude` is mostly runtime state and must never be tracked). Keep employer/machine-specific plugins (e.g. `bcgx-deck`) out of this `settings.json`: install them with `claude plugin install <name> --scope local` inside the relevant project. User-scope plugin installs write through the symlink into the repo, so check `git diff` after installing.

The links are managed with GNU Stow: run `stow .` from the repo root, and `stow -R .` after adding a config. Edits here take effect immediately. Repo-only files at the root must be listed in `.stow-local-ignore`, or they get linked into `$HOME`. This matters most for `CLAUDE.md` and `.claude/`, because `~/CLAUDE.md` would apply to every Claude session under home. Setup steps are in `README.md`; `install.sh` automates them on Arch (pacman packages, oh-my-zsh, backup + stow, hooks, login shell). When a config needs a new package, add it to `PKGS` in `install.sh`.

Commits run `.githooks/pre-commit` at the repo root (`core.hooksPath = .githooks`). It delegates to per-config hooks (currently only nvim's), which run only when their files are staged.

## Per-config guidance

Details for each config live in `.claude/rules/`, one file per config. Each has `paths` frontmatter, so it loads only when working on matching files:

- `nvim.md`: LazyVim layout, tests, theme system
- `zsh.md`: oh-my-zsh custom dir
- `hyprland.md`: Lua config, `hl.dispatch` syntax, validation (also loads for Quickshell)
- `quickshell.md`: bar layout, services, QML conventions
- `ghostty.md`: terminal config
- `matugen.md`: wallpaper colors for Ghostty and Hyprland borders

Add a new rule file when adding a config here, rather than growing this file.

## Always

- Don't launch `qs`; the user keeps it running. Use `qs log` and `qs ipc` against the running instance.
