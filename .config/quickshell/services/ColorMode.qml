pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Light/dark mode. The source of truth is the GNOME `color-scheme` setting, which
// Neovim (lua/util/theme.lua) and GTK apps also follow; it's read on start and
// watched with `gsettings monitor`, so changes from elsewhere show up here too.
// Pushes `dark` into Theme (same reason as WallpaperColors: no import cycle), and
// WallpaperColors regenerates the palette (bar, Ghostty, Hyprland) when it changes.
// From outside: `qs ipc call theme toggle|set <light|dark>|get` (see shell.qml).
Singleton {
    id: root

    readonly property list<string> key: ["org.gnome.desktop.interface", "color-scheme"]
    property bool dark: true
    onDarkChanged: Theme.dark = dark
    Component.onCompleted: Theme.dark = dark

    function toggle() { set(dark ? "light" : "dark"); }

    function set(mode) {
        if (mode !== "light" && mode !== "dark") {
            console.warn(`theme: unknown mode "${mode}" (use light or dark)`);
            return;
        }
        dark = mode === "dark";   // right away; the monitor confirms it
        setter.command = ["gsettings", "set", ...key, `prefer-${mode}`];
        setter.running = true;
    }

    // "'prefer-light'" / "color-scheme: 'prefer-light'" → light; anything else
    // ('default', 'prefer-dark') → dark, matching Neovim's rule.
    function apply(line) {
        if (line.trim() !== "")
            dark = !line.includes("prefer-light");
    }

    Process {
        command: ["gsettings", "get", ...root.key]
        running: true
        stdout: StdioCollector { onStreamFinished: root.apply(text) }
    }

    Process {
        id: monitor
        command: ["gsettings", "monitor", ...root.key]
        running: true
        stdout: SplitParser { onRead: line => root.apply(line) }
        // Shouldn't exit; restart it if it does.
        onExited: restart.start()
    }

    Timer {
        id: restart
        interval: 5000
        onTriggered: monitor.running = true
    }

    Process {
        id: setter
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") console.warn(`theme: gsettings: ${text.trim()}`)
        }
    }
}
