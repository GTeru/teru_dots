import QtQuick
import qs.config
import qs.modules.common

// Round icon button for popups (media controls, mute). `icon` is a glyph from
// config/Icons.qml. Set `enabled: false` to grey it out.
Rectangle {
    id: root
    property alias icon: glyph.text

    signal clicked()

    implicitWidth: 34
    implicitHeight: 34
    radius: width / 2
    color: mouse.containsMouse && enabled ? Theme.popupHover : "transparent"
    opacity: enabled ? 1 : 0.4
    // Squish while pressed, spring back on release.
    scale: mouse.pressed ? 0.85 : 1

    Behavior on color { ColorAnimation { duration: Theme.animDuration } }
    Behavior on opacity { NumberAnimation { duration: Theme.animDuration } }
    Behavior on scale { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutBack } }

    IconText {
        id: glyph
        anchors.centerIn: parent
        font.pixelSize: 20
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.enabled) root.clicked()
    }
}
