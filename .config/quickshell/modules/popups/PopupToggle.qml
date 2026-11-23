import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.common

// Label with an on/off switch. The row doesn't change `checked` itself: handle
// `toggled` and let `checked` follow the real state.
Item {
    id: root
    property string text: ""
    property bool checked: false

    signal toggled()

    Layout.fillWidth: true
    implicitHeight: 28

    BarText {
        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
        text: root.text
    }

    Rectangle {
        id: track
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        width: 34
        height: 18
        radius: 9
        color: root.checked ? Theme.accent : Theme.popupHover

        Behavior on color { ColorAnimation { duration: Theme.animDuration } }

        Rectangle {
            width: 14
            height: 14
            radius: 7
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 2 : 2
            color: Theme.text

            Behavior on x { NumberAnimation { duration: Theme.animDuration * 1.5; easing.type: Easing.OutBack } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
