import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.common

// Clickable list row: `text` on the left, optional `detail` on the right.
// `active` highlights it (e.g. the connected network, the current output).
Rectangle {
    id: root
    property string text: ""
    property string detail: ""
    property bool active: false

    signal clicked()

    Layout.fillWidth: true
    implicitHeight: 28
    radius: 6
    color: mouse.containsMouse ? Theme.popupHover : "transparent"

    Behavior on color { ColorAnimation { duration: Theme.animDuration } }

    BarText {
        anchors { left: parent.left; leftMargin: 8; right: detailText.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        text: root.text
        elide: Text.ElideRight
        color: root.active ? Theme.accent : Theme.text
        font.bold: root.active
    }

    BarText {
        id: detailText
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        text: root.detail
        color: Theme.textMuted
        font.bold: false
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
