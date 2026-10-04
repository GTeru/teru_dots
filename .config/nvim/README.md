# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

## Setup

Steps to get this configuration working on **macOS** and **Omarchy** (Arch Linux).

### 1. Core dependencies

| Tool           | Purpose                                        |
| -------------- | ---------------------------------------------- |
| `neovim` ≥ 0.10 | Editor.                                        |
| `git`          | LazyVim + `lazy.nvim` plugin bootstrap.        |
| `ripgrep`      | Snacks picker / LazyVim grep.                  |
| `fd`           | Snacks picker file finder.                     |
| `lazygit`      | Git UI (LazyVim + Snacks integration).         |
| C toolchain    | Compile tree-sitter parsers (`gcc`/`clang`, `make`). |
| `unzip`, `curl`, `wget` | Mason LSP downloads.                  |
| Clipboard tool | System clipboard integration.                  |
| Nerd Font      | Icons in statusline, pickers, explorer.        |

#### macOS

Prereq: [Homebrew](https://brew.sh).

```sh
brew install neovim git ripgrep fd lazygit gcc make unzip curl wget
brew install --cask font-fira-code-nerd-font
```

Clipboard works out of the box (`pbcopy`/`pbpaste`).

#### Omarchy (Arch Linux)

```sh
sudo pacman -S neovim git ripgrep fd lazygit base-devel unzip curl wget wl-clipboard
```

`base-devel` covers `gcc` + `make`. `wl-clipboard` = Wayland clipboard (Omarchy default). On X11 use `xclip` or `xsel` instead.

FiraCode Nerd Font:

```sh
yay -S ttf-firacode-nerd
# or via pacman if available:
# sudo pacman -S ttf-firacode-nerd
```

Then set your terminal font to **FiraCode Nerd Font**.

### 2. Node + language runtimes (via [mise](https://mise.jdx.dev))

`mise` = polyglot version manager. Works on both platforms with same commands.

#### Install mise

**macOS:**

```sh
brew install mise
```

**Omarchy:**

```sh
yay -S mise
# or bootstrap script:
# curl https://mise.run | sh
```

Activate in shell (`~/.zshrc` or `~/.bashrc`):

```sh
eval "$(mise activate zsh)"   # or: mise activate bash
```

#### Install runtimes

Node is required for several Mason LSPs (`typescript-language-server`, `bash-language-server`, etc.):

```sh
mise use -g node@lts
```

Optional language runtimes (install only what you edit):

```sh
mise use -g python@latest
mise use -g go@latest
mise use -g rust@latest
```

### 3. Claude Code CLI

Used by [`coder/claudecode.nvim`](https://github.com/coder/claudecode.nvim) (`lua/plugins/claudecode.lua`).

Install via official standalone installer (no npm needed):

```sh
curl -fsSL https://claude.ai/install.sh | sh
```

Verify:

```sh
claude --version
```

### 4. First launch

This config is part of the `teru_dots` repo and is linked into `~/.config/nvim` with GNU Stow. See the [root README](../../README.md) for clone and stow steps. Then:

```sh
nvim
```

`lazy.nvim` bootstraps, installs plugins, compiles tree-sitter parsers, and Mason pulls LSPs. Run `:checkhealth` to confirm no missing deps.

### Optional

- **`tree-sitter` CLI** — only needed for building parsers from source or writing custom grammars. `brew install tree-sitter` / `pacman -S tree-sitter`.
- **Extra language servers** — installed on demand via `:Mason`.

## Smoke test

`scripts/smoke-test.sh` boots Neovim headlessly and fails if the config emits any startup error. Runs in under a second once plugins are installed.

Run it manually any time:

```sh
scripts/smoke-test.sh          # fast: startup check only
scripts/smoke-test.sh --sync   # also runs :Lazy! sync (needs network)
```

### Wire it as a pre-commit hook

This config lives inside a dotfiles repo. The repo-root `.githooks/pre-commit` calls `.config/nvim/.githooks/pre-commit` (smoke test + plenary tests) only when files under `.config/nvim/` are staged. Enable it once per clone from the repo root:

```sh
git config core.hooksPath .githooks
```

Bypass in an emergency with `git commit --no-verify` (avoid unless you know why).
