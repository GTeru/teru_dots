import QtQuick
import qs.config
import qs.services
import qs.modules.popups

// Music note while something is playing (muted when paused). Click: media popup.
// Hidden when no player is open.
BarButton {
    id: root
    popupId: "media"
    readonly property var player: Media.player

    visible: player !== null
    icon: Icons.music
    labelColor: player?.isPlaying ? Theme.text : Theme.fgMuted
    opacity: player?.isPlaying ? 1 : 0.6

    MediaPopup {
        anchorItem: root
        popupId: root.popupId
        monitorName: root.monitorName
        player: root.player
    }
}
