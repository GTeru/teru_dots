import QtQuick
import qs.config
import qs.services
import qs.modules.common

// Small bar button that toggles a popup (see modules/popups/). Highlighted
// while its popup is open. Declare the popup inside the button, with
// `anchorItem: <button id>`. Without a `popupId` it just emits `clicked`.
Rectangle {
    id: root
    required property var monitor          // HyprlandMonitor of the bar
    property string popupId: ""
    property alias label: text.text
    property alias labelColor: text.color
    // Set to true and handle `scrolled` to use the wheel; otherwise scrolling
    // falls through to the bar (workspace switching).
    property bool handlesWheel: false
    readonly property string monitorName: monitor?.name ?? ""
    readonly property bool open: popupId !== "" && Popups.isOpen(popupId, monitorName)

    signal scrolled(int delta)
    signal clicked()

    implicitWidth: text.implicitWidth + 14
    implicitHeight: 22
    radius: 11
    color: open || mouse.containsMouse ? Theme.bgHover : "transparent"

    Behavior on color { ColorAnimation { duration: Theme.animDuration } }

    Rectangle {
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
        height: 2
        radius: 1
        width: root.open ? parent.width - 10 : 0
        color: Theme.accent

        Behavior on width { NumberAnimation { duration: Theme.popupAnimDuration; easing.type: Easing.OutCubic } }
    }

    BarText {
        id: text
        anchors.centerIn: parent
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.popupId !== "" ? Popups.toggle(root.popupId, root.monitorName) : root.clicked()
        onWheel: wheel => {
            wheel.accepted = root.handlesWheel;
            if (root.handlesWheel)
                root.scrolled(wheel.angleDelta.y);
        }
    }
}
