import QtQuick
import qs.config
import qs.services
import qs.modules.popups

// Bell with the number of notifications in the history (badged when there are
// any), crossed out while do-not-disturb is on. Click: history popup. Right-click toggles do-not-disturb.
BarButton {
    id: root
    popupId: "notifications"

    icon: Notifications.dnd ? Icons.bellOff : Notifications.count > 0 ? Icons.bellBadge : Icons.bellOutline
    label: !Notifications.dnd && Notifications.count > 0 ? `${Notifications.count}` : ""
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
