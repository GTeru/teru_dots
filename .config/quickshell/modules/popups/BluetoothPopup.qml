import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth: power switch, scan switch, and devices. Click a device to
// connect / disconnect, or to pair it if it was found by a scan.
PopupPanel {
    id: root
    title: "Bluetooth"

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false
    // rfkill block (airplane mode or a hardware switch): enabling fails until it's lifted.
    readonly property bool blocked: adapter?.state === BluetoothAdapterState.Blocked
    // Paired devices always; unpaired ones only while scanning. Connected first.
    readonly property var devices: (adapter?.devices.values ?? [])
        .filter(d => d.paired || d.connected || (adapter.discovering && d.name))
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired))

    // battery may be 0..1 or 0..100; show a percentage either way.
    function percent(v) { return Math.round(v > 1 ? v : v * 100); }

    function detailFor(d) {
        if (d.pairing) return "pairing…";
        if (d.connected) return d.batteryAvailable ? `${percent(d.battery)}%` : "connected";
        if (!d.paired) return "pair";
        return "";
    }

    // Stop scanning when the popup closes.
    Connections {
        target: root
        function onVisibleChanged() {
            if (!root.visible && root.adapter?.discovering)
                root.adapter.discovering = false;
        }
    }

    PopupLabel { visible: root.adapter === null; text: "No Bluetooth adapter" }

    PopupToggle {
        visible: root.adapter !== null
        text: "Bluetooth"
        checked: root.on
        onToggled: {
            if (root.blocked)
                Quickshell.execDetached(["rfkill", "unblock", "bluetooth"]);
            else
                root.adapter.enabled = !root.adapter.enabled;
        }
    }

    PopupLabel { visible: root.blocked; text: "Blocked by rfkill. Toggle to unblock." }

    PopupToggle {
        visible: root.on
        text: "Scan for devices"
        checked: root.adapter?.discovering ?? false
        onToggled: root.adapter.discovering = !root.adapter.discovering
    }

    PopupDivider { visible: root.on }
    PopupLabel { visible: root.on && root.devices.length === 0; text: "No paired devices" }

    Repeater {
        model: root.on ? root.devices : []

        PopupRow {
            required property var modelData
            text: modelData.name || modelData.address
            detail: root.detailFor(modelData)
            active: modelData.connected
            onClicked: {
                if (modelData.connected)
                    modelData.disconnect();
                else if (modelData.paired)
                    modelData.connect();
                else if (!modelData.pairing)
                    modelData.pair();
            }
        }
    }
}
