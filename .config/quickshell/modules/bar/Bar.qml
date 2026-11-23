import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

// Top bar for a single screen. Instantiated once per monitor by shell.qml.
//
// Auto-hides: the bar slides up out of view `Theme.barHideDelay` ms after the
// mouse leaves it. Touching the top screen edge (a thin invisible strip) brings it
// back. Other reasons to show it (workspace change, rename, ...) are listed in
// services/BarReveal.qml.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    // Hyprland's view of this window's monitor.
    readonly property var monitor: Hyprland.monitorFor(screen)

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: Theme.barHeight
    color: "transparent"

    // Float over windows instead of reserving space, so hiding doesn't resize them.
    exclusionMode: ExclusionMode.Ignore

    // Take the keyboard only while renaming a workspace shown on this bar.
    readonly property bool renaming: WorkspaceNames.editingId !== -1
        && monitor?.activeWorkspace?.id === WorkspaceNames.editingId
    WlrLayershell.keyboardFocus: renaming ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // --- Auto-hide state ---
    property bool held: true   // set by peek(); shown on startup, then hides after the delay
    // A BarReveal.hold() for this monitor (or all monitors) is active.
    readonly property bool holding: Object.values(BarReveal.holds)
        .some(m => m === "" || m === bar.monitor?.name)
    readonly property bool revealed: held || holding || hover.hovered

    function peek() {
        held = true;
        if (!hover.hovered)
            hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: Theme.barHideDelay
        running: true
        onTriggered: bar.held = false
    }

    Connections {
        target: BarReveal
        function onPeekRequested(monitor) {
            if (monitor === "" || monitor === bar.monitor?.name)
                bar.peek();
        }
    }

    // Only the visible part takes clicks: the bar when shown, the edge strip when hidden.
    // Everything else passes through to the windows below.
    mask: Region { item: bar.revealed ? panel : edge }

    HoverHandler {
        id: hover
        onHoveredChanged: hovered ? hideTimer.stop() : hideTimer.restart()
    }

    // Invisible strip along the top edge; hovering it reveals the bar.
    Item {
        id: edge
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: Theme.barRevealEdge
    }

    Rectangle {
        id: panel
        width: parent.width
        height: Theme.barHeight
        y: bar.revealed ? 0 : -height
        color: Theme.bg

        Behavior on y { NumberAnimation { duration: Theme.animDuration * 1.5; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.barPadding
            anchors.rightMargin: Theme.barPadding

            // Scroll anywhere on the bar to move between workspaces on this monitor.
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                // Step through 1..Config.workspaceCount (including empty ones), clamped at the ends.
                onWheel: event => {
                    const current = bar.monitor?.activeWorkspace?.id ?? 1;
                    const target = Math.max(1, Math.min(Config.workspaceCount, current + (event.angleDelta.y > 0 ? -1 : 1)));
                    if (target !== current)
                        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${target} })`);
                }
            }

            // Left
            Workspaces { monitor: bar.monitor }

            Item { Layout.fillWidth: true }

            // Right
            RowLayout {
                spacing: Theme.widgetSpacing

                // Buttons open popups from modules/popups/.
                MediaButton { monitor: bar.monitor }
                NetworkButton { monitor: bar.monitor }
                BluetoothButton { monitor: bar.monitor }
                VolumeButton { monitor: bar.monitor }
                BatteryButton { monitor: bar.monitor }
                ThemeButton { monitor: bar.monitor }
                Tray {}
            }
        }

        // Center: anchored to the panel, not the RowLayout, so it stays centered
        // regardless of how wide the left/right sides are.
        Row {
            anchors.centerIn: parent
            spacing: 16

            Row {
                spacing: Theme.widgetSpacing
                DateButton { monitor: bar.monitor }
                Clock { monitor: bar.monitor }
            }
            WeatherIndicator { anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
