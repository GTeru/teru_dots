import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

// Workspace pills 1..count for one monitor, labelled via WorkspaceNames.label.
// Click to switch. While WorkspaceNames.editingId is this monitor's active workspace,
// that pill turns into a text field (Enter saves, empty clears, Escape cancels).
RowLayout {
    id: root
    required property var monitor   // HyprlandMonitor of the bar's screen
    property int count: Config.workspaceCount

    spacing: 4

    Repeater {
        model: root.count

        Rectangle {
            id: pill
            required property int index
            readonly property int wsId: index + 1
            readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId)
            // Workspace shown on this monitor (each monitor has its own).
            readonly property bool isActive: root.monitor?.activeWorkspace?.id === wsId
            // Workspace that currently has keyboard focus (across all monitors).
            readonly property bool isFocused: Hyprland.focusedWorkspace?.id === wsId
            readonly property bool isOccupied: (ws?.toplevels?.values?.length ?? 0) > 0
            // Only the bar showing this workspace edits it (other monitors have a pill with the same id).
            readonly property bool isEditing: isActive && WorkspaceNames.editingId === wsId

            Layout.alignment: Qt.AlignVCenter
            // Grow to fit the label; the active pill is a bit wider.
            implicitWidth: Math.max(20, (isEditing ? editor.implicitWidth : label.implicitWidth) + 12) + (isActive ? 8 : 0)
            implicitHeight: 20
            radius: 10
            color: isActive ? (isFocused ? Theme.accent : Theme.accentDim)
                 : mouse.containsMouse ? Theme.bgHover : "transparent"

            Behavior on implicitWidth { NumberAnimation { duration: Theme.animDuration } }
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }

            Text {
                id: label
                anchors.centerIn: parent
                visible: !pill.isEditing
                text: WorkspaceNames.label(pill.wsId, pill.isOccupied)
                color: pill.isActive ? Theme.bg
                     : pill.isOccupied ? Theme.fg
                     : Theme.fgMuted
                font { pixelSize: 13; bold: true }
            }

            Row {
                id: editor
                anchors.centerIn: parent
                visible: pill.isEditing

                Text {
                    text: `${pill.wsId}-`
                    color: Theme.bg
                    font { pixelSize: 13; bold: true }
                }

                TextInput {
                    id: input
                    width: Math.max(contentWidth, 30)
                    color: Theme.bg
                    selectionColor: Theme.bg
                    selectedTextColor: Theme.accent
                    font { pixelSize: 13; bold: true }

                    onAccepted: WorkspaceNames.setName(pill.wsId, text)
                    Keys.onEscapePressed: WorkspaceNames.cancelRename()
                }
            }

            onIsEditingChanged: {
                if (isEditing) {
                    input.text = WorkspaceNames.nameOf(wsId);
                    input.selectAll();
                    input.forceActiveFocus();
                }
            }

            MouseArea {
                id: mouse
                enabled: !pill.isEditing
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                // Hyprland 0.57 (Lua config) expects a Lua dispatcher expression, not "workspace N".
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${pill.wsId} })`)
            }
        }
    }
}
