pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import QtQuick
import qs.config

// Which bar popup is open: at most one, on one monitor (Hyprland monitor name).
// Bar buttons call toggle(); modules/popups/PopupPanel.qml shows itself when
// isOpen() matches. BarReveal keeps the bar shown while a popup is open.
//
// Two ways to open:
//   toggle(id, monitor)  the user clicked a button: interactive, grabs input,
//                        closes on an outside click / Escape
//   peek(id, monitor)    something changed (volume, track): `peeking`: no input
//                        grab, closes after Config.popupPeekDuration unless hovered.
//                        Never replaces a popup the user opened. Clicking the
//                        button of a peeked popup makes it interactive.
// Triggers for peek() are in the TRIGGERS section below.
Singleton {
    id: root

    property string openId: ""
    property string monitor: ""
    property bool peeking: false
    // True while switching straight from one popup to another (see PopupPanel).
    property bool switching: false
    // Set by PopupPanel while the pointer is over it; a hovered peek stays open.
    property bool hovered: false

    // Last close, so the outside click that closed a popup doesn't reopen it
    // when that click lands on the popup's own button.
    property string lastClosedId: ""
    property real lastClosedAt: 0

    // Triggers are ignored right after startup / reload, when Pipewire and Mpris
    // fill in their initial values.
    property bool ready: false
    Timer { interval: 2000; running: true; onTriggered: root.ready = true }

    function isOpen(id, mon) {
        return openId === id && monitor === (mon ?? "");
    }

    function focusedMonitor() {
        return Hyprland.focusedMonitor?.name ?? "";
    }

    function show(id, mon, isPeek) {
        const open = () => {
            monitor = mon ?? "";
            peeking = isPeek;
            switching = false;
            openId = id;
            if (isPeek)
                peekTimer.restart();
        };
        if (openId === "") {
            open();
        } else {
            // Let the old popup close before the new one opens.
            // Wayland wants one grabbing popup at a time.
            switching = true;
            openId = "";
            Qt.callLater(open);
        }
    }

    function toggle(id, mon) {
        if (isOpen(id, mon)) {
            if (peeking)
                show(id, mon, false);   // peeked → interactive
            else
                close();
            return;
        }
        if (lastClosedId === id && Date.now() - lastClosedAt < 300)
            return;
        show(id, mon, false);
    }

    function peek(id, mon) {
        if (!ready)
            return;
        if (openId !== "" && !peeking)
            return;
        if (isOpen(id, mon)) {
            peekTimer.restart();
            return;
        }
        show(id, mon, true);
    }

    function close() {
        if (openId === "")
            return;
        peekTimer.stop();
        lastClosedId = openId;
        lastClosedAt = Date.now();
        openId = "";
        peeking = false;
    }

    Timer {
        id: peekTimer
        interval: Config.popupPeekDuration
        onTriggered: if (root.peeking && !root.hovered) root.close()
    }
    onHoveredChanged: if (!hovered && peeking) peekTimer.restart()

    // ======================= TRIGGERS =======================

    // Volume / mute change (volume keys, scrolling the button): peek the sound popup.
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    Connections {
        target: Pipewire.defaultAudioSink?.audio ?? null
        function onVolumeChanged() { root.peek("volume", root.focusedMonitor()); }
        function onMutedChanged() { root.peek("volume", root.focusedMonitor()); }
    }

    // Play / pause and track change (media keys, next / previous) on any player:
    // peek the media popup. This also fires when a playlist moves to the next song.
    Instantiator {
        model: Mpris.players
        delegate: Connections {
            required property var modelData
            target: modelData
            function onIsPlayingChanged() { root.peek("media", root.focusedMonitor()); }
            function onTrackTitleChanged() { root.peek("media", root.focusedMonitor()); }
        }
    }
}
