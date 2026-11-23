import QtQuick
import qs.config
import qs.services
import qs.modules.popups

// Battery icon + percent, e.g. "🔋 83%" (⚡ when plugged in). Yellow / red below
// Config.batteryWarn / batteryCritical. Click: battery popup. Hidden without a battery.
BarButton {
    id: root
    popupId: "battery"
    readonly property int percent: BatteryInfo.percent

    visible: BatteryInfo.present
    label: `${BatteryInfo.charging ? "⚡" : percent <= Config.batteryWarn ? "🪫" : "🔋"} ${percent}%`
    labelColor: BatteryInfo.charging ? Theme.good
        : percent <= Config.batteryCritical ? Theme.critical
        : percent <= Config.batteryWarn ? Theme.warn
        : Theme.text

    BatteryPopup {
        anchorItem: root
        popupId: root.popupId
        monitorName: root.monitorName
    }
}
