# teru_dots

Personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

| Path in repo          | Linked to               | What                               |
| --------------------- | ----------------------- | ---------------------------------- |
| `.config/nvim/`       | `~/.config/nvim`        | LazyVim-based Neovim config        |
| `.oh-my-zsh/custom/`  | `~/.oh-my-zsh/custom`   | oh-my-zsh aliases, plugins, themes |

## How it works

The repo mirrors the layout of `$HOME`. Stow creates symlinks in your home directory that point back into the repo:

```
~/.config/nvim       -> teru_dots/.config/nvim
~/.oh-my-zsh/custom  -> teru_dots/.oh-my-zsh/custom
```

Because the configs are symlinks, editing a file in the repo changes the live config right away. Commit and push the repo to keep it in sync across machines.

Files that only belong to the repo (`README.md`, `CLAUDE.md`, `LICENSE`, `.githooks/`, …) are listed in `.stow-local-ignore`, so they never get linked into `$HOME`.

## Setup on a new machine

### 1. Install dependencies

```sh
# Omarchy / Arch
sudo pacman -S git stow zsh eza starship

# macOS
brew install git stow zsh eza starship
```

Starship is the prompt (config in `.config/starship.toml`). On other Linux distros: `curl -sS https://starship.rs/install.sh | sh`

Install [oh-my-zsh](https://ohmyz.sh/#install) first. This repo only provides its `custom/` folder.

For Neovim's own dependencies (ripgrep, fd, Nerd Font, mise, …), see [`.config/nvim/README.md`](.config/nvim/README.md).

### 2. Clone into your home directory

```sh
git clone https://github.com/GTeru/teru_dots.git ~/teru_dots
cd ~/teru_dots
```

Clone it **directly inside `~`** (e.g. `~/teru_dots` or `~/dotfiles`). By default, Stow links into the parent of the folder you run it from, so `stow .` inside `~/teru_dots` targets `~`.

If you clone somewhere else (e.g. `~/code/teru_dots`), pass the target explicitly every time: `stow -t ~ .`

### 3. Move existing configs out of the way

Stow never overwrites real files. If one is in the way, it aborts and makes no changes:

```
WARNING! stowing . would cause conflicts:
  * cannot stow .../.oh-my-zsh/custom/example.zsh over existing target ...
All operations aborted.
```

A fresh oh-my-zsh install creates its own `~/.oh-my-zsh/custom/`, so that one will almost always conflict. Back up anything that's in the way:

```sh
mv ~/.oh-my-zsh/custom ~/.oh-my-zsh/custom.bak
mv ~/.config/nvim ~/.config/nvim.bak   # only if you already had an nvim config
```

### 4. Create the symlinks

Do a dry run first to see what would be linked:

```sh
stow -n -v .
```

Then do it for real:

```sh
stow -v .
```

Check the result:

```sh
ls -l ~/.config/nvim ~/.oh-my-zsh/custom   # both should be symlinks into ~/teru_dots
```

Open a new shell to load the zsh config. Run `nvim` to bootstrap the plugins.

### 5. Enable the git hooks

```sh
git config core.hooksPath .githooks
```

When files under `.config/nvim/` are staged, the pre-commit hook runs the Neovim smoke test and tests. Otherwise it does nothing.

## Day-to-day

| Task                                   | Command (from the repo root) |
| -------------------------------------- | ---------------------------- |
| Preview changes                        | `stow -n -v .`               |
| Link everything                        | `stow .`                     |
| Re-link after adding/removing configs  | `stow -R .`                  |
| Remove all symlinks (repo is untouched) | `stow -D .`                  |

### Adding a new config

Put it in the repo at the same path it has under `$HOME`, then restow. For example, to manage `~/.config/kitty`:

```sh
mv ~/.config/kitty ~/teru_dots/.config/kitty
cd ~/teru_dots && stow -R .
```

If the parent folder already exists in `~` (as `~/.config` does), Stow descends into it and links only the new item. If the parent doesn't exist yet, Stow links the whole folder.

To keep a new repo-only file out of `$HOME`, add an anchored pattern (e.g. `^/notes\.md$`) to `.stow-local-ignore`.

`stow --adopt .` is another way to bring in existing files: it moves them into the repo and links them. It **overwrites the repo's copy** with the machine's version, so run `git diff` afterwards and `git checkout -- <file>` anything you didn't mean to change.
