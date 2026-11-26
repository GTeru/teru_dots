pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Current weather from wttr.in (no API key; location detected from IP, metric units).
// Refreshes every `interval` ms; call refresh() to update now.
Singleton {
    id: root

    property int interval: 15 * 60 * 1000

    property string icon: ""        // glyph from config/Icons.qml, see iconFor()
    property string temperature: "" // e.g. "28°C"
    property string condition: ""   // e.g. "Light rain shower"
    property string location: ""
    readonly property bool ready: temperature !== ""

    function refresh() {
        if (!proc.running)
            proc.running = true;
    }

    // wttr.in's plain-text condition symbol (format %x) → icon.
    function iconFor(symbol) {
        switch (symbol) {
        case "o": return Icons.weatherSunny;
        case "m": return Icons.weatherPartlyCloudy;
        case "mm":
        case "mmm": return Icons.weatherCloudy;
        case "=": return Icons.weatherFog;
        case "/":
        case ".": return Icons.weatherRainy;
        case "//":
        case "///": return Icons.weatherPouring;
        case "x":
        case "x/": return Icons.weatherSnowyRainy;
        case "*":
        case "*/": return Icons.weatherSnowy;
        case "**":
        case "*/*": return Icons.weatherSnowyHeavy;
        case "!/":
        case "/!/": return Icons.weatherLightningRainy;
        case "*!*": return Icons.weatherLightning;
        default: return Icons.weatherCloudyAlert;   // "?" (unknown)
        }
    }

    Process {
        id: proc
        command: ["curl", "-sf", "--max-time", "10", "https://wttr.in/?format=%x|%t|%C|%l&m"]
        stdout: StdioCollector {
            onStreamFinished: {
                // ".|+28°C|Patchy rain nearby|São Paulo, São Paulo, BR"
                const parts = text.trim().split("|");
                if (parts.length < 4)
                    return; // failed/odd response: keep the last good value
                root.icon = root.iconFor(parts[0].trim());
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
