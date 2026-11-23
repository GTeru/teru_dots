import QtQuick
import Quickshell.Services.Pipewire

// Sound: speaker and mic volume, plus the output device list.
PopupPanel {
    id: root
    title: "Sound"

    // Real output devices (not app streams).
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)

    PopupLabel { text: "Output" }
    VolumeRow { node: Pipewire.defaultAudioSink }

    PopupLabel { text: "Microphone"; visible: Pipewire.defaultAudioSource !== null }
    VolumeRow { node: Pipewire.defaultAudioSource; icon: "🎙️"; mutedIcon: "🔇" }

    PopupDivider { visible: root.sinks.length > 1 }
    PopupLabel { text: "Output device"; visible: root.sinks.length > 1 }

    Repeater {
        model: root.sinks.length > 1 ? root.sinks : []

        PopupRow {
            required property var modelData
            text: modelData.description || modelData.nickname || modelData.name
            active: modelData === Pipewire.defaultAudioSink
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }
}
