---
paths:
  - ".config/matugen/**"
---

# matugen (`.config/matugen/`)

Wallpaper-driven colors (matugen 4.x, Material You, light or dark following Quickshell's `ColorMode`). Quickshell's `services/WallpaperColors.qml` runs `matugen image <wallpaper> --mode <light|dark> --source-color-index 0 --json hex` on every wallpaper or mode change. It reads the JSON for the bar, and the same run renders the templates in `config.toml` and runs their `post_hook`s. Details for the bar side are in `quickshell.md`.

- Templates are in `templates/` and render to `~/.cache/wallpaper-colors/`, outside the repo. Variables look like `{{colors.primary.default.hex}}`; `hex_stripped` drops the `#` (for Hyprland's `rgba(...)`). Filters need a color first: `{{colors.primary.default.hex | to_color | set_lightness: 75 | format: "hex_stripped"}}` (piping `colors.x.default` itself panics). The Hyprland focused border uses this to make the pastel Material tones vivid. List color names with `qs ipc call palette get`.
- `ghostty` is included from `config.ghostty` via `config-file = ?~/.cache/wallpaper-colors/ghostty`. Hook: `pkill -USR2 -x ghostty` (Ghostty 1.2+ reloads config on SIGUSR2). Only background/foreground/cursor/selection are themed. Dark mode keeps Ghostty's default ANSI colors so red still reads as red. Light mode (`<* if {{ is_dark_mode }} *> … <* else *> … <* endif *>`) uses `surface_dim` with `set_lightness: 80` as the background (`surface` is near-white, `surface_dim` ~86% still too bright), and a fixed Tokyo Night Day ANSI palette made for light backgrounds. Conditionals only take a boolean like `is_dark_mode`; `{{ mode }} == "light"` is a parse error.
- `hyprland.lua` is a partial `hl.config` for `general.col.*`. `hypr/modules/look.lua` `dofile`s it if it exists (startup and `hyprctl reload`), and the hook applies it live with `hyprctl eval`. The `col` values in `look.lua` are the fallback.
- Don't add a `[config.wallpaper]` section: Quickshell draws the wallpaper itself.
- Regenerate after editing a template: `qs ipc call palette refresh`. Check with `cat ~/.cache/wallpaper-colors/*`, `hyprctl getoption general:col.active_border`, `ghostty +show-config | grep ^background`.
