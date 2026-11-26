import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.services
import qs.modules.common

// App launcher: a search field and a list of apps (services/Launcher.qml), centered
// over a dimmed screen on the monitor it was opened on. Type to filter; Up/Down,
// Tab/Shift+Tab, Ctrl+N/P or Ctrl+J/K move; Enter or a click launches; Escape or a
// click outside closes. Instantiated per screen by shell.qml.
PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    // From modelData, not `screen` (see NotificationToasts).
    readonly property var monitor: Hyprland.monitorFor(modelData)
    readonly property bool shown: Launcher.open && Launcher.monitor === monitor?.name

    // 0 → 1 on open, back to 0 on close; the window stays mapped until it's 0.
    property real progress: shown ? 1 : 0
    Behavior on progress {
        NumberAnimation {
            duration: root.shown ? Theme.popupAnimDuration : Theme.popupAnimDuration * 0.6
            easing.type: root.shown ? Easing.OutCubic : Easing.InCubic
        }
    }
    visible: shown || progress > 0

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // No input while it fades out, so clicks reach the windows below.
    mask: Region { item: root.shown ? backdrop : null }

    readonly property var results: Launcher.search(search.text)

    // Last pointer position over a row (window coordinates), so only a real
    // pointer move selects a row, not rows scrolling under a still pointer.
    property point lastPointer
    property bool pointerSeen: false

    onShownChanged: {
        if (!shown)
            return;
        search.text = "";
        list.currentIndex = 0;
        list.positionViewAtBeginning();
        pointerSeen = false;
        search.forceActiveFocus();
    }

    function iconSource(icon) {
        if (!icon)
            return "";
        if (icon.startsWith("/"))
            return "file://" + icon;
        return Quickshell.iconPath(icon, true);
    }

    function move(delta) {
        if (list.count > 0)
            list.currentIndex = Math.max(0, Math.min(list.count - 1, list.currentIndex + delta));
    }

    function handleKey(event) {
        const ctrl = event.modifiers & Qt.ControlModifier;
        switch (event.key) {
        case Qt.Key_Escape:
            Launcher.close();
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            Launcher.launch(results[list.currentIndex]);
            break;
        case Qt.Key_Down:
        case Qt.Key_Tab:
            move(1);
            break;
        case Qt.Key_Up:
        case Qt.Key_Backtab:
            move(-1);
            break;
        case Qt.Key_PageDown:
            move(Theme.launcherMaxRows);
            break;
        case Qt.Key_PageUp:
            move(-Theme.launcherMaxRows);
            break;
        case Qt.Key_N:
        case Qt.Key_J:
            if (!ctrl)
                return;
            move(1);
            break;
        case Qt.Key_P:
        case Qt.Key_K:
            if (!ctrl)
                return;
            move(-1);
            break;
        default:
            return;
        }
        event.accepted = true;
    }

    // Dimmed screen; a click on it closes the launcher.
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "black"
        opacity: Theme.launcherDim * root.progress

        MouseArea {
            anchors.fill: parent
            onClicked: Launcher.close()
        }
    }

    Rectangle {
        id: card
        width: Math.min(Theme.launcherWidth, parent.width - 32)
        height: column.implicitHeight + 2 * Theme.popupPadding
        x: Math.round((parent.width - width) / 2)
        // Fixed top edge, so the field stays put as the list grows and shrinks.
        // Starts slightly raised and settles into place.
        y: Math.round(parent.height * 0.2) - 10 * (1 - root.progress)
        radius: Theme.launcherRadius
        color: Theme.popupBg
        border.color: Theme.popupBorder
        opacity: root.progress
        scale: 0.97 + 0.03 * root.progress

        // Swallows clicks on the card's padding, which would otherwise close it.
        MouseArea { anchors.fill: parent }

        Column {
            id: column
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.popupPadding }
            spacing: 6

            Item {
                width: parent.width
                height: 44

                Text {
                    id: glyph
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    text: "🔍"
                    font.pixelSize: 16
                    opacity: 0.7
                }

                TextInput {
                    id: search
                    anchors { left: glyph.right; leftMargin: 12; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    color: Theme.text
                    selectionColor: Theme.accentDim
                    selectedTextColor: Theme.text
                    font.pixelSize: Theme.launcherFontSize
                    clip: true
                    focus: true
                    onTextChanged: {
                        list.currentIndex = 0;
                        list.positionViewAtBeginning();
                    }
                    Keys.onPressed: event => root.handleKey(event)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: search.text === ""
                        text: "Search apps…"
                        color: Theme.textMuted
                        font.pixelSize: Theme.launcherFontSize
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.popupBorder
                visible: list.count > 0 || search.text !== ""
            }

            ListView {
                id: list
                width: parent.width
                height: Math.min(count, Theme.launcherMaxRows) * Theme.launcherRowHeight
                visible: count > 0
                clip: true
                model: root.results
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: Rectangle {
                    id: row
                    required property var modelData   // DesktopEntry
                    required property int index
                    readonly property bool selected: index === ListView.view.currentIndex
                    readonly property string iconUrl: root.iconSource(modelData.icon)

                    width: ListView.view.width
                    height: Theme.launcherRowHeight
                    radius: Theme.popupRadius
                    color: selected ? Theme.popupHover : "transparent"

                    Item {
                        id: iconBox
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        width: Theme.launcherIconSize
                        height: Theme.launcherIconSize

                        IconImage {
                            anchors.fill: parent
                            visible: row.iconUrl !== ""
                            source: row.iconUrl
                            asynchronous: true
                        }

                        // No icon in the theme: the app's initial.
                        Rectangle {
                            anchors.fill: parent
                            visible: row.iconUrl === ""
                            radius: 8
                            color: Theme.accent

                            Text {
                                anchors.centerIn: parent
                                text: row.modelData.name.charAt(0).toUpperCase()
                                color: Theme.onAccent
                                font { pixelSize: 16; bold: true }
                            }
                        }
                    }

                    Column {
                        anchors { left: iconBox.right; leftMargin: 12; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                        spacing: 1

                        BarText {
                            width: parent.width
                            elide: Text.ElideRight
                            text: row.modelData.name
                            color: row.selected ? Theme.accent : Theme.text
                            font.pixelSize: 14
                        }
                        BarText {
                            width: parent.width
                            elide: Text.ElideRight
                            visible: text !== ""
                            text: row.modelData.genericName || row.modelData.comment || ""
                            color: Theme.textMuted
                            font { pixelSize: 11; bold: false }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: mouse => {
                            const p = mapToItem(null, mouse.x, mouse.y);
                            if (root.pointerSeen && (p.x !== root.lastPointer.x || p.y !== root.lastPointer.y))
                                list.currentIndex = row.index;
                            root.lastPointer = p;
                            root.pointerSeen = true;
                        }
                        onClicked: Launcher.launch(row.modelData)
                    }
                }
            }

            BarText {
                visible: list.count === 0 && search.text !== ""
                leftPadding: 10
                height: Theme.launcherRowHeight
                text: "No matching apps"
                color: Theme.textMuted
                font.bold: false
            }
        }
    }
}
