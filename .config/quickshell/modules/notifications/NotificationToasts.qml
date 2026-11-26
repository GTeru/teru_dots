import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.services
import qs.modules.common

// Toasts for new notifications, stacked newest-first in the top-right corner of
// the focused monitor, just under the bar. Which ones show (and for how long)
// is decided by services/Notifications.qml. Instantiated per screen by shell.qml.
PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    // From modelData, not `screen`: the window's screen changes as it's shown/hidden,
    // which made `visible` depend on itself.
    readonly property var monitor: Hyprland.monitorFor(modelData)
    readonly property bool focused: monitor?.name === Hyprland.focusedMonitor?.name
    visible: focused && Object.keys(Notifications.toasts).length > 0

    anchors.top: true
    anchors.right: true
    margins.top: Theme.barHeight + Theme.popupGap
    margins.right: Theme.popupGap
    implicitWidth: Theme.toastWidth
    // Fixed height; the mask lets clicks below the stack through.
    implicitHeight: Math.round((modelData?.height ?? 1080) * 0.8)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region { item: stack }

    // Tracks the whole stack: hover pauses every toast's timeout.
    HoverHandler {
        onHoveredChanged: Notifications.toastsHovered = hovered
    }

    ListView {
        id: stack
        width: parent.width
        height: contentHeight
        interactive: false
        // Newest (last in the model) on top.
        verticalLayoutDirection: ListView.BottomToTop
        model: Notifications.list

        delegate: Item {
            id: slot
            required property var modelData
            readonly property bool shown: Notifications.isToast(modelData.id)
            // false for one frame after creation, so a new toast slides in.
            property bool entered: false
            Component.onCompleted: Qt.callLater(() => slot.entered = true)

            width: ListView.view.width
            height: shown ? card.implicitHeight + 8 : 0
            visible: height > 0
            clip: true

            Behavior on height { NumberAnimation { duration: Theme.popupAnimDuration; easing.type: Easing.OutCubic } }

            NotificationCard {
                id: card
                notif: slot.modelData
                width: parent.width
                height: implicitHeight
                x: slot.shown && slot.entered ? 0 : parent.width + 20
                opacity: slot.shown && slot.entered ? 1 : 0

                Behavior on x { NumberAnimation { duration: Theme.popupAnimDuration; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: Theme.popupAnimDuration } }
            }
        }
    }
}
