import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.common

// Month calendar. ‹ / › (or the mouse wheel over the grid) change month; clicking
// the month title goes back to today's. Opens on the current month. Weeks start
// on the locale's first day; today is filled with the accent color.
PopupPanel {
    id: root
    title: "Calendar"
    property date now

    // Month shown, as a year and 0-based month.
    property int year: now.getFullYear()
    property int month: now.getMonth()

    readonly property bool isCurrentMonth: year === now.getFullYear() && month === now.getMonth()
    readonly property int firstDay: Qt.locale().firstDayOfWeek   // 0 = Sunday, like Date.getDay()

    function goToday() {
        year = now.getFullYear();
        month = now.getMonth();
    }

    function shift(delta) {
        const d = new Date(year, month + delta, 1);
        year = d.getFullYear();
        month = d.getMonth();
    }

    onShouldShowChanged: if (shouldShow) goToday()

    // 6 weeks × 7 days from the start of the week holding the 1st:
    // [{ day, inMonth, today }]
    readonly property var days: {
        const first = new Date(year, month, 1);
        const lead = (first.getDay() - firstDay + 7) % 7;
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(year, month, 1 - lead + i);
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === month,
                today: d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth()
                    && d.getDate() === now.getDate()
            });
        }
        return out;
    }

    // Header: ‹  November 2026  ›
    RowLayout {
        Layout.fillWidth: true

        NavButton { text: "‹"; onClicked: root.shift(-1) }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 26
            radius: 6
            color: titleMouse.containsMouse && !root.isCurrentMonth ? Theme.popupHover : "transparent"

            BarText {
                anchors.centerIn: parent
                text: Qt.locale().standaloneMonthName(root.month) + " " + root.year
                color: root.isCurrentMonth ? Theme.text : Theme.accent
            }

            MouseArea {
                id: titleMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.isCurrentMonth ? Qt.ArrowCursor : Qt.PointingHandCursor
                onClicked: root.goToday()
            }
        }

        NavButton { text: "›"; onClicked: root.shift(1) }
    }

    Grid {
        id: grid
        readonly property real cell: width / 7
        Layout.fillWidth: true
        columns: 7

        // Weekday initials, starting at the locale's first day.
        Repeater {
            model: 7
            BarText {
                required property int index
                width: grid.cell
                height: 24
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale().dayName((root.firstDay + index) % 7, Locale.ShortFormat)
                color: Theme.textMuted
                font { pixelSize: 11; bold: false }
            }
        }

        Repeater {
            model: root.days

            Item {
                required property var modelData
                width: grid.cell
                height: 30

                Rectangle {
                    anchors.centerIn: parent
                    width: 26
                    height: 26
                    radius: 13
                    visible: parent.modelData.today
                    color: Theme.accent
                }

                BarText {
                    anchors.centerIn: parent
                    text: parent.modelData.day
                    color: parent.modelData.today ? Theme.onAccent
                        : parent.modelData.inMonth ? Theme.text : Theme.textMuted
                    font.bold: parent.modelData.today
                    opacity: parent.modelData.inMonth ? 1 : 0.6
                }
            }
        }

        // Scroll to change month.
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => root.shift(event.angleDelta.y > 0 ? -1 : 1)
        }
    }
}
