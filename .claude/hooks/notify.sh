#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
msg="${1:-Claude finished}"
input=$(cat)

session_title() {
  local tp cwd name=""
  tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
  if [ -n "$tp" ] && [ -f "$tp" ]; then
    name=$(grep -h '"type":"custom-title"' "$tp" | tail -1 | jq -r '.customTitle // empty' 2>/dev/null)
    [ -z "$name" ] && name=$(grep -h '"type":"ai-title"' "$tp" | tail -1 | jq -r '.aiTitle // empty' 2>/dev/null)
  fi
  [ -z "$name" ] && name=$(basename "${cwd:-$PWD}")
  printf 'Claude Code · %s' "$name"
}

notify_macos() {
  local my_tty="" pid=$$ t front focused_tty term_id title
  while [ "$pid" -gt 1 ]; do
    t=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
    if [ -n "$t" ] && [ "$t" != "??" ]; then my_tty="$t"; break; fi
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  done

  front=$(lsappinfo info -only bundleid "$(lsappinfo front)" 2>/dev/null | sed -n 's/.*="\(.*\)"/\1/p')
  case "$front" in
    com.mitchellh.ghostty)
      focused_tty=$(osascript -e 'tell application "Ghostty" to get tty of focused terminal of selected tab of front window' 2>/dev/null)
      [ -n "$my_tty" ] && [ "$focused_tty" = "/dev/$my_tty" ] && exit 0
      ;;
    com.apple.Terminal|com.googlecode.iterm2|dev.warp.Warp-Stable|net.kovidgoyal.kitty|org.alacritty|com.github.wez.wezterm) exit 0 ;;
  esac

  title=$(session_title)

  term_id=""
  [ -n "$my_tty" ] && term_id=$(osascript -e "tell application \"Ghostty\" to get id of first terminal whose tty is \"/dev/$my_tty\"" 2>/dev/null)

  if command -v terminal-notifier >/dev/null 2>&1; then
    if [ -n "$term_id" ]; then
      terminal-notifier -title "$title" -message "$msg" -sound Hero -group "claude-$term_id" \
        -execute "osascript -e 'tell application \"Ghostty\" to activate' -e 'tell application \"Ghostty\" to focus (first terminal whose id is \"$term_id\")'" \
        >/dev/null 2>&1 || true
    else
      terminal-notifier -title "$title" -message "$msg" -sound Hero -activate com.mitchellh.ghostty >/dev/null 2>&1 || true
    fi
  else
    osascript \
      -e 'on run argv' \
      -e 'display notification (item 1 of argv) with title (item 2 of argv) sound name "Hero"' \
      -e 'end run' \
      -- "$msg" "$title" >/dev/null 2>&1 || true
  fi
}

notify_linux() {
  local title active_class my_tty="" pid=$$ t
  title=$(session_title)

  # Parsed without jq, which isn't always installed.
  if command -v hyprctl >/dev/null 2>&1; then
    active_class=$(hyprctl activewindow 2>/dev/null | sed -n 's/^[[:space:]]*class: //p' | tr '[:upper:]' '[:lower:]')
    case "$active_class" in
      com.mitchellh.ghostty|ghostty|kitty|alacritty|foot|org.wezfurlong.wezterm) exit 0 ;;
    esac
  fi

  # The session's terminal: the first ancestor with a tty (ps prints "?" for none).
  while [ "$pid" -gt 1 ]; do
    t=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
    if [ -n "$t" ] && [ "$t" != "?" ]; then my_tty="$t"; break; fi
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  done

  if command -v canberra-gtk-play >/dev/null 2>&1; then
    (canberra-gtk-play -i complete >/dev/null 2>&1 &)
  elif command -v paplay >/dev/null 2>&1 && [ -f /usr/share/sounds/freedesktop/stereo/complete.oga ]; then
    (paplay /usr/share/sounds/freedesktop/stereo/complete.oga >/dev/null 2>&1 &)
  fi

  # In Ghostty, let the terminal send it (OSC 777): clicking a notification
  # Ghostty sent brings up the exact window and tab it came from. ';' would end
  # the title field, so it's replaced.
  if [ "$TERM_PROGRAM" = "ghostty" ] && [ -n "$my_tty" ] && [ -w "/dev/$my_tty" ]; then
    printf '\033]777;notify;%s;%s\a' "${title//;/,}" "$msg" > "/dev/$my_tty" 2>/dev/null && return
  fi

  command -v notify-send >/dev/null 2>&1 || exit 0

  # Fallback: focus any Ghostty window on click. Hyprland's Lua config needs a
  # Lua dispatcher expression, not "focuswindow class:...".
  if command -v hyprctl >/dev/null 2>&1 && notify-send --help 2>&1 | grep -q -- '--action'; then
    (
      action=$(notify-send -a "Claude Code" -u critical -t 0 -A "default=Open" --wait "$title" "$msg" 2>/dev/null)
      [ "$action" = "default" ] && hyprctl dispatch 'hl.dsp.focus({ window = "class:com.mitchellh.ghostty" })' >/dev/null 2>&1
    ) >/dev/null 2>&1 &
  else
    notify-send -a "Claude Code" -u critical -t 0 "$title" "$msg" >/dev/null 2>&1 || true
  fi
}

case "$(uname -s)" in
  Darwin) notify_macos ;;
  Linux)  notify_linux ;;
esac
exit 0
