import QtQuick
import qs.config
import qs.services
import qs.modules.popups

// 🔔 with the number of notifications in the history, 🔕 while do-not-disturb
// is on. Click: history popup. Right-click toggles do-not-disturb.
BarButton {
    id: root
    popupId: "notifications"

    label: Notifications.dnd ? "🔕" : Notifications.count > 0 ? `🔔 ${Notifications.count}` : "🔔"
    labelColor: Notifications.count > 0 && !Notifications.dnd ? Theme.accent : Theme.text

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: Notifications.toggleDnd()
    }

    NotificationPopup {
        anchorItem: root
        popupId: root.popupId
        monitorName: root.monitorName
    }
}
