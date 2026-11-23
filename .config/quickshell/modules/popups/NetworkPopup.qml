import QtQuick
import Quickshell
import Quickshell.Networking
import qs.config
import qs.services

// Wi-Fi: on/off switch and the list of nearby networks.
// Click a network to connect (known or open networks) or disconnect. New
// password-protected networks open in nmtui, since the bar can't take typing here.
PopupPanel {
    id: root
    title: "Wi-Fi"

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    // Connected first, then by signal strength. Hidden networks (no name) are skipped.
    readonly property var networks: (wifi?.networks.values ?? [])
        .filter(n => n.name)
        .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))

    function openNmtui(args) {
        Quickshell.execDetached([Config.terminal, "-e", "nmtui"].concat(args ?? []));
        Popups.close();
    }

    // signalStrength may be 0..1 or 0..100 depending on the backend; show bars either way.
    function bars(strength) {
        const s = strength > 1 ? strength / 100 : strength;
        return s > 0.75 ? "▂▄▆█" : s > 0.5 ? "▂▄▆_" : s > 0.25 ? "▂▄__" : "▂___";
    }

    // Scan for networks only while this popup is open.
    Binding {
        target: root.wifi
        property: "scannerEnabled"
        value: root.visible
        when: root.wifi !== null
    }

    PopupToggle {
        text: "Wi-Fi"
        checked: Networking.wifiEnabled
        onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
    }

    PopupDivider { visible: Networking.wifiEnabled }
    PopupLabel {
        visible: Networking.wifiEnabled && root.networks.length === 0
        text: "Searching…"
    }

    Repeater {
        model: Networking.wifiEnabled ? root.networks : []

        PopupRow {
            required property var modelData
            readonly property bool secured: modelData.security !== WifiSecurityType.Open
            text: modelData.name
            detail: `${modelData.stateChanging ? "…  " : ""}${secured ? "🔒 " : ""}${root.bars(modelData.signalStrength)}`
            active: modelData.connected
            onClicked: {
                if (modelData.connected)
                    modelData.disconnect();
                else if (modelData.known || !secured)
                    modelData.connect();
                else
                    root.openNmtui(["connect", modelData.name]);
            }
        }
    }

    PopupDivider {}
    PopupRow {
        text: "Network settings…"
        onClicked: root.openNmtui()
    }
}
