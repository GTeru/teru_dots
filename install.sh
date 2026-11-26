#!/usr/bin/env bash
# Set up these dotfiles on Arch Linux:
#   1. install pacman packages
#   2. install oh-my-zsh (if missing)
#   3. back up anything in $HOME that would block stow, then link the configs
#   4. enable the repo's git hooks and make zsh the login shell
#
# Usage: ./install.sh [--dry-run] [--no-packages]
# Safe to re-run: pacman uses --needed and already-linked configs are skipped.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0
PACKAGES=1

PKGS=(
  # base + shell
  git stow zsh eza starship curl wget unzip
  # desktop: Hyprland, bar, terminal, programs used by keybinds (hypr/modules/)
  hyprland xdg-desktop-portal-hyprland polkit quickshell ghostty wofi dolphin
  pipewire pipewire-pulse wireplumber brightnessctl playerctl wl-clipboard
  # fonts: emoji (bar weather icon), Nerd Font (nvim icons)
  noto-fonts-emoji ttf-firacode-nerd
  # .webp wallpapers, wallpaper colors
  qt6-imageformats matugen
  # Claude Code notify hook (.claude/hooks/notify.sh): session titles, notify-send fallback
  jq libnotify
  # neovim + its tools (.config/nvim/README.md)
  neovim base-devel ripgrep fd lazygit mise tree-sitter-cli python-pipx
)

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --no-packages) PACKAGES=0 ;;
    -h | --help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
run() {
  if ((DRY_RUN)); then
    printf '    [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

[[ $EUID -ne 0 ]] || { echo "run as your user, not root (sudo is used where needed)" >&2; exit 1; }
command -v pacman >/dev/null || { echo "pacman not found: this script is for Arch Linux" >&2; exit 1; }

# 1. packages
if ((PACKAGES)); then
  log "Installing packages"
  run sudo pacman -S --needed "${PKGS[@]}"
fi

# 2. oh-my-zsh (only its custom/ dir lives in this repo)
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log "Installing oh-my-zsh"
  run git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi

# 3. back up blockers, then stow.
# Link units: each .config/<name>, .oh-my-zsh/custom, and other root entries
# that .stow-local-ignore doesn't exclude.
is_ignored() {
  local pat
  while IFS= read -r pat; do
    [[ -z "$pat" || "$pat" == \#* ]] && continue
    grep -qE -- "$pat" <<<"/$1" && return 0
  done <"$REPO/.stow-local-ignore"
  return 1
}

units=()
for path in "$REPO"/.[!.]* "$REPO"/*; do
  [[ -e "$path" ]] || continue
  name="${path##*/}"
  is_ignored "$name" && continue
  case "$name" in
    .config) for c in "$path"/*; do [[ -e "$c" ]] && units+=(".config/${c##*/}"); done ;;
    .oh-my-zsh) units+=(".oh-my-zsh/custom") ;;
    *) units+=("$name") ;;
  esac
done

log "Checking for existing configs in the way"
for u in "${units[@]}"; do
  target="$HOME/$u"
  [[ -e "$target" || -L "$target" ]] || continue
  [[ "$(readlink -f "$target")" == "$REPO/$u" ]] && continue # already linked
  echo "    backing up ~/$u -> ${BACKUP/#$HOME/\~}/$u"
  run mkdir -p "$(dirname "$BACKUP/$u")"
  run mv "$target" "$BACKUP/$u"
done

log "Linking configs with stow"
if ((DRY_RUN)); then
  stow -n -v -d "$REPO" -t "$HOME" -R . 2>&1 | grep -v 'reverts previous action' | sed 's/^/    /' || true
else
  stow -d "$REPO" -t "$HOME" -R .
fi

# 4. repo hooks + login shell
log "Enabling git hooks"
run git -C "$REPO" config core.hooksPath .githooks

if [[ "$(getent passwd "$USER" | cut -d: -f7)" != */zsh ]]; then
  log "Setting zsh as login shell"
  run chsh -s "$(command -v zsh || echo /usr/bin/zsh)"
fi

log "Done. Open a new terminal, then run nvim to bootstrap plugins."
echo "    Not handled here: 'mise use -g node@lts', Claude Code CLI, 'pipx install jupytext' (see .config/nvim/README.md)."
