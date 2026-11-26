pragma Singleton

import Quickshell
import QtQuick

// Behavior settings (non-visual). Use with `import qs.config` → Config.workspaceCount etc.
// Workspace names are set at runtime, see services/WorkspaceNames.qml.
Singleton {
    // Number of workspace pills shown in the bar (1..workspaceCount).
    readonly property int workspaceCount: 9

    // Terminal used by bar click actions (keep in sync with hypr/modules/programs.lua).
    readonly property string terminal: "ghostty"

    // How long a popup opened by a change (volume, track) stays up, in ms.
    readonly property int popupPeekDuration: 2500

    // Battery percentage thresholds for the warn / critical colors.
    readonly property int batteryWarn: 20
    readonly property int batteryCritical: 10

    // Default timezones for the clock popup, 3 per row (names from /usr/share/zoneinfo).
    // Shown sorted by UTC offset, latest first. Clocks swapped from the popup are
    // saved by services/WorldClocks.qml and override this list.
    readonly property var worldClocks: ["America/Los_Angeles", "America/New_York", "UTC", "Europe/London", "Asia/Tokyo", "Australia/Sydney"]

    // Notification toasts: how long one stays up (ms, unless the app asks for
    // another timeout; critical ones stay until closed), and how many at once.
    readonly property int notificationTimeout: 5000
    readonly property int notificationMaxToasts: 4

    // matugen --type, e.g. scheme-tonal-spot, scheme-vibrant, scheme-expressive.
    readonly property string paletteScheme: "scheme-tonal-spot"
}
