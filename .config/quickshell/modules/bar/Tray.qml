import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.config
import qs.modules.common

// App tray icons (StatusNotifierItem), collapsed behind a chevron toggle at the far
// right of the bar. Clicking the toggle slides the icons out to its left.
// Left click on an icon activates the app, right click opens its menu, scroll is
// passed to the app. Not named SystemTray, which is the service singleton.
Row {
    id: root
    property bool expanded: false

    visible: SystemTray.items.values.length > 0

    // Icons, clipped to an animated width so they slide out from the toggle.
    Item {
        id: drawer
        anchors.verticalCenter: parent.verticalCenter
        height: icons.implicitHeight
        width: root.expanded ? icons.implicitWidth + 6 : 0
        clip: true

        Behavior on width { NumberAnimation { duration: Theme.popupAnimDuration; easing.type: Easing.OutCubic } }

        Row {
            id: icons
            anchors.right: parent.right
            anchors.rightMargin: 6
            spacing: 6

            Repeater {
                model: SystemTray.items

                IconImage {
                    id: icon
                    required property var modelData   // SystemTrayItem
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: Theme.trayIconSize
                    source: modelData.icon

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: mouse => {
                            const item = icon.modelData;
                            if (mouse.button === Qt.MiddleButton) {
                                item.secondaryActivate();
                            } else if (mouse.button === Qt.RightButton || item.onlyMenu) {
                                if (item.hasMenu) {
                                    // Menu opens just below the icon, relative to the bar window.
                                    const p = icon.mapToItem(null, 0, icon.height);
                                    item.display(icon.QsWindow.window, p.x, p.y);
                                }
                            } else {
                                item.activate();
                            }
                        }
                        // Handled here so it doesn't also switch workspaces (the bar's WheelHandler).
                        onWheel: wheel => icon.modelData.scroll(wheel.angleDelta.y, false)
                    }
                }
            }
        }
    }

    // Toggle, styled like BarButton (which is tied to popups, so not reused here).
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: arrow.implicitWidth + 14
        implicitHeight: 22
        radius: 11
        color: root.expanded || toggleMouse.containsMouse ? Theme.bgHover : "transparent"

        Behavior on color { ColorAnimation { duration: Theme.animDuration } }

        IconText {
            id: arrow
            anchors.centerIn: parent
            text: Icons.chevronLeft
            rotation: root.expanded ? 180 : 0

            Behavior on rotation { NumberAnimation { duration: Theme.popupAnimDuration; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            id: toggleMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }
}
