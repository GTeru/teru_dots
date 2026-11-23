pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Timezones shown in the clock popup (modules/popups/ClockPopup.qml). Starts as
// Config.worldClocks; swapping one from the popup saves the list to
// ~/.local/state/quickshell/by-shell/<id>/world-clocks.json (Quickshell.statePath).
Singleton {
    id: root

    readonly property list<string> zones: adapter.zones.length > 0 ? adapter.zones : Config.worldClocks
    // Every zone `timedatectl` knows, for the picker. Loaded once.
    property list<string> available: []

    // Swap `oldTz` for `newTz`, keeping the rest.
    function replace(oldTz, newTz) {
        if (oldTz === newTz || !available.includes(newTz))
            return;
        adapter.zones = zones.map(tz => tz === oldTz ? newTz : tz);
    }

    // Back to Config.worldClocks.
    function reset() {
        adapter.zones = [];
    }

    Process {
        command: ["timedatectl", "list-timezones"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.available = text.trim().split("\n").filter(tz => tz !== "")
        }
    }

    FileView {
        path: Quickshell.statePath("world-clocks.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter
            property list<string> zones: []   // empty: use Config.worldClocks
        }
    }
}
