pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Runs matugen on the wallpaper, in ColorMode's light/dark mode, and writes its
// colors to Theme.scheme. Reruns when either changes.
// Pushes into Theme because Theme importing qs.services would be an import cycle.
Singleton {
    id: root

    readonly property string source: Wallpaper.current
    readonly property string mode: ColorMode.dark ? "dark" : "light"
    // What's wanted vs. what the last run was for; a change mid-run reruns after it.
    readonly property string wanted: `${mode} ${source}`
    onWantedChanged: refresh()

    property string generatedFor: ""

    function refresh() {
        if (source === "") {
            Theme.scheme = {};
            generatedFor = "";
            return;
        }
        if (proc.running)
            return;
        generatedFor = wanted;
        proc.command = ["matugen", "image", source,
            "--mode", mode,
            "--type", Config.paletteScheme,
            "--source-color-index", "0",
            "--json", "hex"];
        proc.running = true;
    }

    function parse(text) {
        const colors = JSON.parse(text).colors;
        const scheme = {};
        for (const name in colors)
            scheme[name] = colors[name].default.color;
        return scheme;
    }

    Process {
        id: proc
        stdout: StdioCollector {
            id: out
        }
        stderr: StdioCollector {
            id: err
        }
        onExited: code => {
            if (code === 0) {
                try {
                    Theme.scheme = root.parse(out.text);
                } catch (e) {
                    console.warn(`palette: can't parse matugen output: ${e}`);
                }
            } else {
                console.warn(`palette: matugen exited ${code}: ${err.text.trim()}`);
            }
            if (root.generatedFor !== root.wanted)
                root.refresh();
        }
    }
}
