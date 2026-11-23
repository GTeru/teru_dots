import QtQuick
import Quickshell.Networking
import qs.config
import qs.modules.popups

// Network icon: 🌐 wired, 📶 Wi-Fi, 📵 offline / Wi-Fi off. Click: Wi-Fi popup.
BarButton {
    id: root
    popupId: "network"
    readonly property var devices: Networking.devices.values
    readonly property bool wired: devices.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property bool wifi: devices.some(d => d.type === DeviceType.Wifi && d.connected)

    label: wired ? "🌐" : wifi ? "📶" : "📵"
    labelColor: wired || wifi ? Theme.text : Theme.fgMuted

    NetworkPopup {
        anchorItem: root
        popupId: root.popupId
        monitorName: root.monitorName
    }
}
