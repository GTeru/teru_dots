-- Quickshell integration. The shell itself lives in ~/.config/quickshell (shell.qml).

-- Start the bar at login. -n exits if an instance is already running,
-- so this never produces a duplicate bar.
hl.on("hyprland.start", function ()
    hl.exec_cmd("qs -n")
end)

-- SUPER+R: rename the focused workspace in the bar (Enter saves, empty clears, Escape cancels).
hl.bind("SUPER + R", hl.dsp.exec_cmd("qs ipc call workspaces rename"))

-- SUPER+SHIFT+W: next wallpaper (images in ~/.config/quickshell/wallpapers).
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("qs ipc call wallpaper next"))
