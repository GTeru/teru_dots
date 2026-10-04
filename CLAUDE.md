# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles. Directories mirror their location under `$HOME` and are wired in by **relative symlinks** pointing back into `~/teru_dots`:

- `~/.config/nvim` → `teru_dots/.config/nvim` (whole directory)
- `~/.oh-my-zsh/custom` → `teru_dots/.oh-my-zsh/custom` (only the `custom/` dir; oh-my-zsh itself is not tracked)

The links are managed with GNU Stow: run `stow .` from the repo root, and `stow -R .` after adding a config. Edits here take effect immediately. Repo-only files at the root must be listed in `.stow-local-ignore`, or they get linked into `$HOME`. This matters most for `CLAUDE.md`, because `~/CLAUDE.md` would apply to every Claude session under home. Setup steps are in `README.md`.

## Neovim (`.config/nvim/`): LazyVim

Run these from `.config/nvim/`:

```sh
scripts/smoke-test.sh            # headless startup, fails on any startup error (<1s)
scripts/smoke-test.sh --sync     # also :Lazy! sync (network)
nvim --headless -c "Lazy load plenary.nvim" -c "PlenaryBustedDirectory tests/ {sequential = true}" -c "qa!"   # all tests
nvim --headless -c "Lazy load plenary.nvim" -c "PlenaryBustedFile tests/util/theme_spec.lua" -c "qa!"          # one spec
stylua lua tests                 # format (stylua.toml: 2 spaces, 120 cols)
```

Commits run `.githooks/pre-commit` at the repo root (`core.hooksPath = .githooks`). It calls `.config/nvim/.githooks/pre-commit`, which runs the smoke test and all tests, but only when files under `.config/nvim/` are staged. The nvim hook finds its paths from its own location, so you can also run it directly.

### Conventions

- One plugin per file in `lua/plugins/`.
- If a keymap belongs to one plugin, put it in that plugin spec's `keys = {}`. Otherwise put it in `lua/config/keymaps.lua`.
- When suggesting a plugin, give a `lazy.nvim` spec that can go straight into `lua/plugins/`. Explain LazyVim overrides with the `opts` / `keys` / `Util.extend` patterns from LazyVim's docs.
- For keymap questions, show where the current binding is defined and give the override snippet.
- Don't invent plugin APIs. If unsure, grep the installed plugin source under `~/.local/share/nvim/lazy/`.
- The user knows Lua basics and is learning nvim/LazyVim internals. Prefer minimal diffs.

### Theme system (spans several files)

- `lua/config/theme.lua` returns the active colorscheme name. LazyVim's `colorscheme` opt in `lua/config/lazy.lua` reads it.
- Every colorscheme plugin spec (`lua/plugins/catppuccin.lua`, `kanagawa.lua`) is wrapped in `require("util.theme").plugin({...})`. The spec needs a `name` that matches the string in `config/theme.lua`. All themes get installed, but only the active one is forced `lazy = false` and calls `M.setup`. Without that, lazy.nvim skips `config()` for colorschemes it can resolve from the runtimepath.
- `lua/util/theme.lua` makes the theme follow the OS light/dark setting:
  - macOS: `defaults read -g AppleInterfaceStyle`
  - Omarchy: `~/.config/omarchy/current/theme.name`, with a fallback to the legacy `current/theme` symlink
  - It re-applies on a 3s timer and on `FocusGained`.
  - Running `:colorscheme` by hand locks it (`vim.g.theme_locked`); `:ThemeAuto` unlocks it. `vim.g._theme_applying` tells the module's own applies apart from the user's.
- `tests/util/theme_spec.lua` (plenary/busted, written Given/Then style) covers this by stubbing `vim.fn.*` and `vim.loop.*`.

To switch themes, change `config/theme.lua`. To add a theme, add a `util.theme.plugin` spec with a matching `name`.

## Zsh (`.oh-my-zsh/custom/`)

oh-my-zsh loads `*.zsh` files here alphabetically, after its built-ins. Personal aliases go in `aliases.zsh`. The `example*` files are oh-my-zsh stubs.

