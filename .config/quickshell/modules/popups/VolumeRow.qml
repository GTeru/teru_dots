import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.config
import qs.modules.common

// Mute button + volume slider + percentage for one Pipewire node (speaker or mic).
RowLayout {
    id: root
    required property var node
    property string icon: "🔊"
    property string mutedIcon: "🔇"
    readonly property var audio: node?.audio ?? null

    // Pipewire only fills in a node's audio properties while something tracks it.
    PwObjectTracker { objects: [root.node] }

    visible: audio !== null
    Layout.fillWidth: true
    spacing: 8

    PopupButton {
        implicitWidth: 28
        implicitHeight: 28
        label: root.audio?.muted ? root.mutedIcon : root.icon
        onClicked: root.audio.muted = !root.audio.muted
    }

    PopupSlider {
        value: root.audio?.volume ?? 0
        opacity: root.audio?.muted ? 0.4 : 1
        // Capped at 100%, like the volume keys (wpctl -l 1).
        onMoved: v => root.audio.volume = v
    }

    BarText {
        Layout.preferredWidth: 38
        horizontalAlignment: Text.AlignRight
        text: `${Math.round((root.audio?.volume ?? 0) * 100)}%`
        color: root.audio?.muted ? Theme.textMuted : Theme.text
    }
}
