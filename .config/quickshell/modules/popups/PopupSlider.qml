import QtQuick
import QtQuick.Layouts
import qs.config

// Horizontal 0..1 slider. Drag, click, or scroll (±5%). Like PopupToggle, it
// only emits `moved`; bind `value` to the real state.
Item {
    id: root
    property real value: 0

    signal moved(real value)

    function clamp(v) { return Math.max(0, Math.min(1, v)); }

    Layout.fillWidth: true
    implicitHeight: 18

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.popupHover

        Rectangle {
            width: parent.width * root.clamp(root.value)
            height: parent.height
            radius: 3
            color: Theme.accent

            Behavior on width { enabled: !mouse.pressed; NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: (root.width - width) * root.clamp(root.value)
        width: 14
        height: 14
        radius: 7
        color: Theme.text
        // Grows a little while hovered or dragged.
        scale: mouse.pressed ? 1.25 : mouse.containsMouse ? 1.1 : 1

        Behavior on x { enabled: !mouse.pressed; NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutBack } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function set(x) { root.moved(root.clamp(x / width)); }
        onPressed: mouse => set(mouse.x)
        onPositionChanged: mouse => { if (pressed) set(mouse.x); }
        onWheel: wheel => root.moved(root.clamp(root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)))
    }
}
