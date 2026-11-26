import QtQuick
import Quickshell.Services.UPower
import qs.config
import qs.services

// Battery: charge, state, time left, and the power profile (power-profiles-daemon).
PopupPanel {
    id: root
    title: "Battery"

    readonly property var device: UPower.displayDevice
    readonly property bool charging: device?.state === UPowerDeviceState.Charging
    readonly property int seconds: charging ? (device?.timeToFull ?? 0) : (device?.timeToEmpty ?? 0)

    function duration(s) {
        const h = Math.floor(s / 3600);
        const m = Math.round((s % 3600) / 60);
        return h > 0 ? `${h}h ${m}m` : `${m}m`;
    }

    PopupLabel {
        text: `${BatteryInfo.percent}% · ${UPowerDeviceState.toString(root.device?.state ?? UPowerDeviceState.Unknown)}`
            + (root.seconds > 0 ? ` · ${root.duration(root.seconds)} ${root.charging ? "until full" : "left"}` : "")
        font.pixelSize: Theme.fontSize
    }

    PopupDivider {}
    PopupLabel { text: "Power profile" }

    Repeater {
        model: PowerProfiles.hasPerformanceProfile
            ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
            : [PowerProfile.PowerSaver, PowerProfile.Balanced]

        PopupRow {
            required property int modelData
            icon: [Icons.leaf, Icons.scaleBalance, Icons.rocketLaunch][modelData]
            text: ["Power saver", "Balanced", "Performance"][modelData]
            active: PowerProfiles.profile === modelData
            onClicked: PowerProfiles.profile = modelData
        }
    }
}
