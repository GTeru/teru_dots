import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.modules.common

// An analog clock for each of WorldClocks.zones, with its digital time and the
// offset from local time, sorted from the latest time to the earliest (top left
// is furthest ahead). Faces are dimmed at night (before 6:00, from 18:00).
// Click a clock to swap it for another timezone: the grid is replaced by a search
// field and a list; Enter picks the first match, Escape goes back.
// QML's Date has no timezone support, so `date` does the conversion; it runs
// when the popup opens, every minute (`now`) while it's open, and when the zones change.
PopupPanel {
    id: root
    title: editing === "" ? "World clock" : `Replace ${label(editing)}`
    property date now

    property var zones: []   // [{ tz, name, time, diff, hour, minute, offset }]
    property string editing: ""   // timezone being replaced, or ""

    function label(tz) { return tz.split("/").pop().replace(/_/g, " "); }

    function refresh() {
        if (!shouldShow)
            return;
        if (proc.running) {
            pending = true;
            return;
        }
        proc.ranFor = WorldClocks.zones.slice();
        proc.command = ["sh", "-c", 'for tz; do TZ="$tz" date "+%a %H:%M %z"; done; date "+%z"', "sh", ...proc.ranFor];
        proc.running = true;
    }
    property bool pending: false

    onShouldShowChanged: {
        if (!shouldShow)
            editing = "";
        refresh();
    }
    // `now` ticks every second (the bar shows seconds); the zones only need the minute.
    readonly property string minute: Qt.formatDateTime(now, "yyyyMMddHHmm")
    onMinuteChanged: refresh()
    Connections {
        target: WorldClocks
        function onZonesChanged() { root.refresh(); }
    }

    function startEditing(tz) {
        editing = tz;
        search.text = "";
        search.forceActiveFocus();
    }

    function pick(tz) {
        WorldClocks.replace(editing, tz);
        editing = "";
    }

    // Matches "new york", "new_york", "america/new" etc., case-insensitively.
    // Hides zones already shown, except the one being replaced.
    readonly property var matches: {
        if (editing === "")
            return [];
        const q = search.text.trim().toLowerCase().replace(/ /g, "_");
        return WorldClocks.available.filter(tz =>
            (tz === editing || !WorldClocks.zones.includes(tz)) && tz.toLowerCase().includes(q));
    }

    // "-0300" → minutes east of UTC.
    function offsetMinutes(z) {
        const sign = z[0] === "-" ? -1 : 1;
        return sign * (parseInt(z.slice(1, 3)) * 60 + parseInt(z.slice(3, 5)));
    }

    function formatDiff(min) {
        if (min === 0)
            return "same";
        const h = Math.floor(Math.abs(min) / 60);
        const m = Math.abs(min) % 60;
        return `${min > 0 ? "+" : "−"}${h}${m ? `:${String(m).padStart(2, "0")}` : ""}h`;
    }

    Process {
        id: proc
        property list<string> ranFor: []
        // One "Mon 05:45 +0900" line per zone, then the local offset.
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const local = root.offsetMinutes(lines[lines.length - 1]);
                root.zones = proc.ranFor.map((tz, i) => {
                    const [day, time, off] = (lines[i] ?? "").split(" ");
                    const [h, m] = (time ?? "0:0").split(":").map(Number);
                    return {
                        tz: tz,
                        name: root.label(tz),
                        time: `${day} ${time}`,
                        hour: h,
                        minute: m,
                        offset: off ? root.offsetMinutes(off) : 0,
                        diff: off ? root.formatDiff(root.offsetMinutes(off) - local) : ""
                    };
                }).sort((a, b) => b.offset - a.offset);   // latest first
            }
        }
        onExited: if (root.pending) { root.pending = false; root.refresh(); }
    }

    PopupLabel {
        text: Qt.formatDateTime(root.now, "dddd, d MMMM yyyy")
        font.pixelSize: Theme.fontSize
    }

    PopupDivider {}

    // Fixed-width cells so every column is the same size, whatever the text.
    Grid {
        id: grid
        readonly property int cellWidth: Math.floor(width / columns)
        visible: root.editing === ""
        Layout.fillWidth: true
        Layout.topMargin: 4
        columns: 3
        rowSpacing: 6

        Repeater {
            model: root.zones

            Rectangle {
                id: zone
                required property var modelData
                width: grid.cellWidth
                height: cell.implicitHeight + 12
                radius: 8
                color: cellMouse.containsMouse ? Theme.popupHover : "transparent"

                Behavior on color { ColorAnimation { duration: Theme.animDuration } }

                Column {
                    id: cell
                    y: 6
                    width: parent.width
                    spacing: 2

                    ClockFace {
                        anchors.horizontalCenter: parent.horizontalCenter
                        hour: zone.modelData.hour
                        minute: zone.modelData.minute
                    }
                    Item { width: 1; height: 4 }
                    BarText { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: zone.modelData.name }
                    BarText { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: zone.modelData.time; color: Theme.accent }
                    BarText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: zone.modelData.diff
                        color: Theme.textMuted
                        font { pixelSize: 11; bold: false }
                    }
                }

                MouseArea {
                    id: cellMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.startEditing(zone.modelData.tz)
                }
            }
        }
    }

    // --- Timezone picker (while editing) ---
    Rectangle {
        visible: root.editing !== ""
        Layout.fillWidth: true
        implicitHeight: 28
        radius: 6
        color: Theme.popupHover
        border { width: 1; color: search.activeFocus ? Theme.accent : "transparent" }

        TextInput {
            id: search
            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.text
            selectionColor: Theme.accentDim
            font.pixelSize: Theme.fontSize
            clip: true

            Keys.onReturnPressed: if (root.matches.length > 0) root.pick(root.matches[0])
            Keys.onEnterPressed: if (root.matches.length > 0) root.pick(root.matches[0])
            // Back to the clocks instead of closing the popup.
            Keys.onEscapePressed: event => { root.editing = ""; event.accepted = true; }
            Keys.onDownPressed: list.forceActiveFocus()

            BarText {
                anchors.verticalCenter: parent.verticalCenter
                visible: search.text === ""
                text: "Search timezones…"
                color: Theme.textMuted
                font.bold: false
            }
        }
    }

    ListView {
        id: list
        visible: root.editing !== ""
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(count, 8) * 28
        clip: true
        model: root.matches
        boundsBehavior: Flickable.StopAtBounds
        keyNavigationEnabled: true
        highlightMoveDuration: 0
        Keys.onReturnPressed: if (currentIndex >= 0) root.pick(root.matches[currentIndex])
        Keys.onEscapePressed: event => { root.editing = ""; event.accepted = true; }
        Keys.onUpPressed: event => {
            if (currentIndex <= 0) search.forceActiveFocus();
            else decrementCurrentIndex();
        }

        delegate: PopupRow {
            required property string modelData
            required property int index
            width: ListView.view.width
            text: root.label(modelData)
            detail: modelData.includes("/") ? modelData.slice(0, modelData.lastIndexOf("/")) : ""
            active: modelData === root.editing || (list.activeFocus && index === list.currentIndex)
            onClicked: root.pick(modelData)
        }
    }

    PopupLabel {
        visible: root.editing !== "" && root.matches.length === 0
        text: "No matching timezone"
    }
}
