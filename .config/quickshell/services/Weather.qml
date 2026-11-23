pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Current weather from wttr.in (no API key; location detected from IP, metric units).
// Refreshes every `interval` ms; call refresh() to update now.
Singleton {
    id: root

    property int interval: 15 * 60 * 1000

    property string icon: ""        // emoji, e.g. "🌦️"
    property string temperature: "" // e.g. "28°C"
    property string condition: ""   // e.g. "Light rain shower"
    property string location: ""
    readonly property bool ready: temperature !== ""

    function refresh() {
        if (!proc.running)
            proc.running = true;
    }

    Process {
        id: proc
        command: ["curl", "-sf", "--max-time", "10", "https://wttr.in/?format=%c|%t|%C|%l&m"]
        stdout: StdioCollector {
            onStreamFinished: {
                // "🌦️ |+28°C|Light rain shower|São Paulo, São Paulo, BR"
                const parts = text.trim().split("|");
                if (parts.length < 4)
                    return; // failed/odd response: keep the last good value
                root.icon = parts[0].trim();
                root.temperature = parts[1].trim().replace(/^\+/, "");
                root.condition = parts[2].trim();
                root.location = parts[3].trim();
            }
        }
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
