import QtQuick
import Quickshell.Bluetooth
import qs.config
import qs.modules.popups

// Bluetooth icon: crossed out and muted when off, accent when a device is connected.
// Click: Bluetooth popup. Hidden when there's no adapter.
BarButton {
    id: root
    popupId: "bluetooth"
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool anyConnected: (adapter?.devices.values ?? []).some(d => d.connected)

    visible: adapter !== null
    icon: !adapter?.enabled ? Icons.bluetoothOff : anyConnected ? Icons.bluetoothConnect : Icons.bluetooth
    labelColor: !adapter?.enabled ? Theme.fgMuted : anyConnected ? Theme.accent : Theme.text

    BluetoothPopup {
        anchorItem: root
        popupId: root.popupId
        monitorName: root.monitorName
    }
}
