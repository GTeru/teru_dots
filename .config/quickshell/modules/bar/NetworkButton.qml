import QtQuick
import Quickshell.Networking
import qs.config
import qs.modules.popups

// Network icon: wired, Wi-Fi, or Wi-Fi off when offline. Click: Wi-Fi popup.
BarButton {
    id: root
    popupId: "network"
    readonly property var devices: Networking.devices.values
    readonly property bool wired: devices.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property bool wifi: devices.some(d => d.type === DeviceType.Wifi && d.connected)

    icon: wired ? Icons.lan : wifi ? Icons.wifi : Icons.wifiOff
    labelColor: wired || wifi ? Theme.text : Theme.fgMuted

    NetworkPopup {
        anchorItem: root
        popupId: root.popupId
        monitorName: root.monitorName
    }
}
