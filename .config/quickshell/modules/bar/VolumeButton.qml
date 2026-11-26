import QtQuick
import Quickshell.Services.Pipewire
import qs.config
import qs.modules.popups

// Speaker icon. Click: sound popup. Scroll: volume ±5%.
BarButton {
    id: root
    popupId: "volume"
    readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null
    readonly property real volume: audio?.volume ?? 0

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    visible: audio !== null
    icon: audio?.muted ? Icons.volumeOff : volume === 0 ? Icons.volumeLow : volume < 0.5 ? Icons.volumeMedium : Icons.volumeHigh

    handlesWheel: true
    // Capped at 100%, like the volume keys (wpctl -l 1).
    onScrolled: delta => audio.volume = Math.max(0, Math.min(1, volume + (delta > 0 ? 0.05 : -0.05)))

    VolumePopup {
        anchorItem: root
        popupId: root.popupId
        monitorName: root.monitorName
    }
}
