import Quickshell
import QtQuick
import qs.config
import qs.modules.popups

// Current time and timezone, e.g. "17:45:09 -03". Click: world clock (ClockPopup).
// The date is DateButton.
BarButton {
    id: root
    popupId: "clock"

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // `t` is the zone's abbreviation (e.g. "-03", "JST").
    label: Qt.formatDateTime(clock.date, "HH:mm:ss t")

    ClockPopup {
        anchorItem: root
        popupId: root.popupId
        monitorName: root.monitorName
        now: clock.date
    }
}
