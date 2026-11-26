import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.common

// Now playing: cover art, track info, and previous / play-pause / next.
PopupPanel {
    id: root
    required property var player   // MprisPlayer
    title: player?.identity ?? "Media"

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Image {
            visible: source.toString() !== "" && status !== Image.Error
            source: root.player?.trackArtUrl ?? ""
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            BarText {
                Layout.fillWidth: true
                text: root.player?.trackTitle || "Unknown track"
                elide: Text.ElideRight
            }
            PopupLabel {
                Layout.leftMargin: 0
                text: root.player?.trackArtist ?? ""
                visible: text !== ""
            }
            PopupLabel {
                Layout.leftMargin: 0
                text: root.player?.trackAlbum ?? ""
                visible: text !== ""
            }
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 12

        PopupButton {
            icon: Icons.skipPrevious
            enabled: root.player?.canGoPrevious ?? false
            onClicked: root.player.previous()
        }
        PopupButton {
            icon: root.player?.isPlaying ? Icons.pause : Icons.play
            enabled: root.player?.canTogglePlaying ?? false
            onClicked: root.player.togglePlaying()
        }
        PopupButton {
            icon: Icons.skipNext
            enabled: root.player?.canGoNext ?? false
            onClicked: root.player.next()
        }
    }
}
