import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.modules.common

// Notification history (newest first), do-not-disturb, and clear all.
PopupPanel {
    id: root
    title: "Notifications"
    implicitWidth: Theme.toastWidth

    PopupToggle {
        text: "🔕 Do not disturb"
        checked: Notifications.dnd
        onToggled: Notifications.toggleDnd()
    }

    PopupRow {
        visible: Notifications.count > 0
        text: "Clear all"
        detail: `${Notifications.count}`
        onClicked: Notifications.clearAll()
    }

    PopupDivider {}

    PopupLabel {
        visible: Notifications.count === 0
        text: "No notifications"
    }

    ListView {
        id: history
        visible: Notifications.count > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, Theme.notificationHistoryHeight)
        clip: true
        spacing: 6
        boundsBehavior: Flickable.StopAtBounds
        verticalLayoutDirection: ListView.BottomToTop
        model: Notifications.list

        // Wheel scrolls the list, not the bar's workspaces.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: wheel => {
                wheel.accepted = true;
                history.flick(0, wheel.angleDelta.y * 8);
            }
        }

        delegate: NotificationCard {
            required property var modelData
            notif: modelData
            width: ListView.view.width
            height: implicitHeight
            bodyLines: 6
            color: Theme.popupHover
            border.color: critical ? Theme.critical : "transparent"
        }
    }
}
