import Quickshell
import QtQuick
import qs.config
import qs.modules.popups

// Current date, e.g. "Mon 23 Nov". Click: month calendar. The time is Clock.
BarButton {
    id: root
    popupId: "calendar"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    label: Qt.formatDateTime(clock.date, "ddd dd MMM")

    CalendarPopup {
        anchorItem: root
        popupId: root.popupId
        monitorName: root.monitorName
        now: clock.date
    }
}
