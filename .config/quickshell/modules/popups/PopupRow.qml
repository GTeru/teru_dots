import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.common

// Clickable list row: optional `icon` and `text` on the left, optional `detailIcon`
// and `detail` on the right (icons are glyphs from config/Icons.qml).
// `active` highlights it (e.g. the connected network, the current output).
Rectangle {
    id: root
    property string icon: ""
    property string text: ""
    property string detailIcon: ""
    property string detail: ""
    property bool active: false

    signal clicked()

    Layout.fillWidth: true
    implicitHeight: 28
    radius: 6
    color: mouse.containsMouse ? Theme.popupHover : "transparent"

    Behavior on color { ColorAnimation { duration: Theme.animDuration } }

    IconText {
        id: iconText
        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
        visible: root.icon !== ""
        width: visible ? implicitWidth : 0
        text: root.icon
        color: root.active ? Theme.accent : Theme.text
    }

    BarText {
        anchors { left: iconText.right; leftMargin: iconText.visible ? 8 : 0; right: detailRow.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        text: root.text
        elide: Text.ElideRight
        color: root.active ? Theme.accent : Theme.text
        font.bold: root.active
    }

    Row {
        id: detailRow
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 6

        IconText {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.detailIcon !== ""
            text: root.detailIcon
            color: Theme.textMuted
            font.pixelSize: Theme.fontSize
        }
        BarText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.detail
            color: Theme.textMuted
            font.bold: false
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
