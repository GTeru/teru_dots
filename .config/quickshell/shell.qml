//@ pragma UseQApplication
// Needed for tray menus (SystemTrayItem.display uses platform menus).

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.bar
import qs.modules.wallpaper
import qs.config
import qs.services

// Entry point. Components live in modules/, shared theme in config/Theme.qml,
// stateful singletons in services/.
ShellRoot {
    Component.onCompleted: WallpaperColors.refresh()

    // One wallpaper per monitor, on the background layer.
    Variants {
        model: Quickshell.screens
        WallpaperWindow {}
    }

    // One bar per monitor.
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    // `qs ipc call workspaces rename` → rename the focused workspace (bound in Hyprland).
    IpcHandler {
        target: "workspaces"
        function rename(): void { WorkspaceNames.startRename(); }
    }

    // `qs ipc call popup toggle <volume|network|bluetooth|battery|media|clock|calendar>` → toggle a
    // bar popup on the focused monitor. `qs ipc call popup close` closes it.
    IpcHandler {
        target: "popup"
        function toggle(id: string): void { Popups.toggle(id, BarReveal.focusedMonitor()); }
        function close(): void { Popups.close(); }
    }

    // `qs ipc call wallpaper next|prev|set <file>|get` → see services/Wallpaper.qml.
    IpcHandler {
        target: "wallpaper"
        function next(): void { Wallpaper.next(); }
        function prev(): void { Wallpaper.prev(); }
        function set(path: string): void { Wallpaper.set(path); }
        function get(): string { return Wallpaper.current; }
    }

    // `qs ipc call palette refresh|get`
    IpcHandler {
        target: "palette"
        function refresh(): void { WallpaperColors.refresh(); }
        function get(): string { return JSON.stringify(Theme.scheme); }
    }

    // `qs ipc call theme toggle|set <light|dark>|get` → see services/ColorMode.qml.
    IpcHandler {
        target: "theme"
        function toggle(): void { ColorMode.toggle(); }
        function set(mode: string): void { ColorMode.set(mode); }
        function get(): string { return ColorMode.dark ? "dark" : "light"; }
    }

    // `qs ipc call bar peek` → show the bar briefly on the focused monitor.
    IpcHandler {
        target: "bar"
        function peek(): void { BarReveal.peek(BarReveal.focusedMonitor()); }
    }
}
