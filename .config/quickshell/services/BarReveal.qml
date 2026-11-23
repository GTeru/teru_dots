pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import QtQuick

// Central list of things that make the (auto-hiding) bar appear.
//
// Two kinds of reveal, both per monitor (by Hyprland monitor name, "" = all monitors):
//   peek(monitor)          show for Theme.barHideDelay, then hide again
//   hold(reason, monitor)  stay shown until release(reason); release peeks once,
//                          so the result stays visible briefly
//
// To add a trigger, add a block to the TRIGGERS section below (or call
// BarReveal.peek/hold/release from anywhere). From outside Quickshell, use
// `qs ipc call bar peek` (see shell.qml).
Singleton {
    id: root

    // Bars connect to this.
    signal peekRequested(string monitor)

    // reason -> monitor name. Reassigned (not mutated) so bindings update.
    property var holds: ({})

    function peek(monitor) {
        peekRequested(monitor ?? "");
    }

    function hold(reason, monitor) {
        const h = Object.assign({}, holds);
        h[reason] = monitor ?? "";
        holds = h;
    }

    function release(reason) {
        if (!(reason in holds))
            return;
        const monitor = holds[reason];
        const h = Object.assign({}, holds);
        delete h[reason];
        holds = h;
        peek(monitor);
    }

    // Monitor that has keyboard focus. Most user actions happen there.
    function focusedMonitor() {
        return Hyprland.focusedMonitor?.name ?? "";
    }

    // ======================= TRIGGERS =======================

    // Workspace change: peek on the monitor that switched.
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { root.peek(root.focusedMonitor()); }
    }

    // Volume / mute change (volume keys, scrolling the indicator): peek on the focused monitor.
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    Connections {
        target: Pipewire.defaultAudioSink?.audio ?? null
        function onVolumeChanged() { root.peek(root.focusedMonitor()); }
        function onMutedChanged() { root.peek(root.focusedMonitor()); }
    }

    // Bar button popup (modules/popups/): hold while it's open.
    Connections {
        target: Popups
        function onOpenIdChanged() {
            if (Popups.openId !== "")
                root.hold("popup", Popups.monitor);
            else
                root.release("popup");
        }
    }

    // Workspace rename (SUPER+R): hold while the editor is open.
    Connections {
        target: WorkspaceNames
        function onEditingIdChanged() {
            if (WorkspaceNames.editingId !== -1)
                root.hold("rename", root.focusedMonitor());
            else
                root.release("rename");
        }
    }
}
