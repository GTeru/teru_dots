import QtQuick
import qs.config
import qs.modules.common

// Small square arrow button for popups (e.g. the calendar's ‹ ›).
Rectangle {
    id: root
    property alias text: label.text
    signal clicked()

    implicitWidth: 26
    implicitHeight: 26
    radius: 6
    color: mouse.containsMouse ? Theme.popupHover : "transparent"

    Behavior on color { ColorAnimation { duration: Theme.animDuration } }

    BarText {
        id: label
        anchors.centerIn: parent
        font.pixelSize: 16
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
