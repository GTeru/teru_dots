import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.modules.common

// Dropdown panel under a bar button. Shown while Popups.isOpen(popupId, monitorName).
// Clicking outside it or pressing Escape closes it. Children go into a ColumnLayout.
// A peeked popup (Popups.peeking) doesn't grab input and stays open while hovered.
//
// Animation: `progress` runs 0 → 1 on open (the panel unrolls downward, fades in
// and settles; the content follows slightly later) and back to 0 on close, after
// which the window is hidden. The window keeps its full size the whole time; only
// what's drawn inside it moves.
PopupWindow {
    id: root
    required property Item anchorItem
    required property string popupId
    required property string monitorName
    property string title: ""
    default property alias content: column.data
    // Not for hidden buttons (e.g. media with no player, opened over IPC).
    readonly property bool shouldShow: Popups.isOpen(popupId, monitorName) && anchorItem.visible

    property real progress: 0

    // Anchored to the bar window at the button's resting position rather than to
    // the button itself, so a popup opened while the bar is still sliding in
    // (peek) lands in the right place. anchorX is set just before showing.
    property real anchorX: 0
    anchor.window: anchorItem.QsWindow.window
    anchor.rect.x: anchorX
    anchor.rect.y: 0
    anchor.rect.width: anchorItem.width
    anchor.rect.height: (Theme.barHeight + anchorItem.height) / 2   // button's bottom edge
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    grabFocus: !Popups.peeking
    color: "transparent"
    implicitWidth: Theme.popupWidth
    implicitHeight: bg.implicitHeight + Theme.popupGap
    visible: false

    // Set imperatively: the compositor also hides the popup on an outside click,
    // and that has to go back into Popups.
    onShouldShowChanged: {
        if (shouldShow) {
            closeAnim.stop();
            anchorX = anchorItem.mapToItem(null, 0, 0).x;
            visible = true;
            openAnim.restart();
        } else if (visible) {
            // Switching straight to another popup: hide at once, since Wayland
            // allows only one grabbing popup at a time.
            if (Popups.switching) {
                visible = false;
            } else {
                openAnim.stop();
                closeAnim.restart();
            }
        }
    }
    onVisibleChanged: {
        if (!visible) {
            openAnim.stop();
            closeAnim.stop();
            progress = 0;
            if (shouldShow)
                Popups.close();
            if (Popups.hovered)
                Popups.hovered = false;
        } else {
            bg.forceActiveFocus();
        }
    }

    NumberAnimation {
        id: openAnim
        target: root
        property: "progress"
        to: 1
        duration: Theme.popupAnimDuration
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closeAnim
        target: root
        property: "progress"
        to: 0
        duration: Theme.popupAnimDuration * 0.6
        easing.type: Easing.InCubic
        onFinished: if (!root.shouldShow) root.visible = false
    }

    // Clips the panel to a height that grows with progress: the "unroll".
    Item {
        id: clipper
        y: Theme.popupGap
        width: parent.width
        height: bg.height * (0.15 + 0.85 * root.progress)
        clip: true
        opacity: Math.min(1, root.progress * 1.6)

        Rectangle {
            id: bg
            width: parent.width
            // Starts slightly raised and settles down into place.
            y: -8 * (1 - root.progress)
            implicitHeight: column.implicitHeight + 2 * Theme.popupPadding
            height: implicitHeight
            color: Theme.popupBg
            border.color: Theme.popupBorder
            radius: Theme.popupRadius
            focus: true
            Keys.onEscapePressed: Popups.close()

            HoverHandler {
                onHoveredChanged: if (root.shouldShow) Popups.hovered = hovered
            }

            ColumnLayout {
                id: column
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.popupPadding }
                // Content trails the panel: fades in over the later part and slides up 6px.
                anchors.topMargin: Theme.popupPadding + 6 * (1 - root.progress)
                opacity: Math.max(0, (root.progress - 0.35) / 0.65)
                spacing: 6

                BarText {
                    visible: root.title !== ""
                    text: root.title
                    Layout.bottomMargin: 2
                }
            }
        }
    }
}
