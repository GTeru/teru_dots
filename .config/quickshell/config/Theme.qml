pragma Singleton

import Quickshell
import QtQuick

// Shared colors and sizes. Colors follow the wallpaper and light/dark mode, with
// Tokyo Night (dark) / Tokyo Night Day (light) fallbacks.
Singleton {
    id: root

    // Set by services/WallpaperColors.qml and services/ColorMode.qml.
    property var scheme: ({})
    property bool dark: true

    // Wallpaper color `name`, else the fallback for the current mode.
    function pick(name, darkFallback, lightFallback) { return scheme[name] ?? (dark ? darkFallback : lightFallback); }

    property color bg: pick("surface", "#1a1b26", "#e1e2e7")
    property color bgHover: pick("surface_container_high", "#292e42", "#c4c8da")
    property color accent: pick("primary", "#0db9d7", "#007197")              // focused workspace
    property color onAccent: pick("on_primary", "#1a1b26", "#e1e2e7")          // text on an accent fill
    property color accentDim: pick("primary_container", "#3d59a1", "#b7c1e3") // active on another monitor
    property color fg: pick("secondary", "#7aa2f7", "#2e7de9")                // occupied
    property color fgMuted: pick("outline_variant", "#444b6a", "#a8aecb")     // empty workspaces, ticks: not for text
    property color textMuted: pick("on_surface_variant", "#a9b1d6", "#6172b0") // secondary text (labels, details)
    property color text: pick("on_surface", "#c0caf5", "#3760bf")             // general text (clock, weather)
    // Light popups use surface_dim, not the pure-white surface_container_lowest. Not
    // darker than that: primary (accent) text would drop below 4.5:1.
    property color popupBg: pick(dark ? "surface_container_lowest" : "surface_dim", "#16161e", "#d0d5e3")
    property color popupBorder: pick(dark ? "surface_container_high" : "outline", "#292e42", "#a8aecb")
    // Hover / track color inside popups; bgHover would be lighter than a light popupBg.
    readonly property color popupHover: dark ? bgHover : Qt.darker(popupBg, 1.08)

    Behavior on bg { ColorAnimation { duration: root.wallpaperFadeDuration } }
    Behavior on bgHover { ColorAnimation { duration: root.wallpaperFadeDuration } }
    Behavior on accent { ColorAnimation { duration: root.wallpaperFadeDuration } }
    Behavior on accentDim { ColorAnimation { duration: root.wallpaperFadeDuration } }
    Behavior on fg { ColorAnimation { duration: root.wallpaperFadeDuration } }
    Behavior on fgMuted { ColorAnimation { duration: root.wallpaperFadeDuration } }
    Behavior on textMuted { ColorAnimation { duration: root.wallpaperFadeDuration } }
    Behavior on text { ColorAnimation { duration: root.wallpaperFadeDuration } }
    Behavior on popupBg { ColorAnimation { duration: root.wallpaperFadeDuration } }
    Behavior on popupBorder { ColorAnimation { duration: root.wallpaperFadeDuration } }

    // Not from the wallpaper, so green/yellow/red always mean the same thing.
    readonly property color good: dark ? "#9ece6a" : "#587539"       // charging
    readonly property color warn: dark ? "#e0af68" : "#8c6c3e"       // battery low
    readonly property color critical: dark ? "#f7768e" : "#f52a65"   // battery critical

    readonly property int barHeight: 30
    readonly property int barPadding: 8
    readonly property int barHideDelay: 500    // ms after the mouse leaves before the bar hides
    readonly property int barRevealEdge: 2     // px strip at the top screen edge that reveals it
    readonly property int animDuration: 120

    readonly property int fontSize: 13
    readonly property int widgetSpacing: 4     // gap between right-side buttons
    readonly property int trayIconSize: 16

    // Popups opened from bar buttons (modules/popups/); colors are above.
    readonly property int popupWidth: 300
    readonly property int popupPadding: 12
    readonly property int popupGap: 6          // px between the bar and the popup
    readonly property int popupRadius: 10
    readonly property int popupAnimDuration: 260   // open; close runs at 60%

    // Notification toasts (modules/notifications/) and the history popup.
    readonly property int toastWidth: 360
    readonly property int notificationHistoryHeight: 480   // max; scrolls past this

    readonly property int wallpaperFadeDuration: 800   // crossfade when the wallpaper changes
}
