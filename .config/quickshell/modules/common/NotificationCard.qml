import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

// One notification: icon, app · time, summary, body, action buttons, and ×.
// Clicking the card runs the "default" action if the app gave one. Used by the
// toasts (modules/notifications/) and the bar popup's history, so it lives here.
Rectangle {
    id: root
    required property var notif
    property int bodyLines: 4
    // Shown as a toast (not in the history popup): clicking closes it.
    property bool toast: false

    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical
    readonly property var defaultAction: notif?.actions.find(a => a.identifier === "default") ?? null
    // Ghostty (and other GNotification apps) send no app name; use the desktop entry's.
    readonly property string appLabel: notif?.appName || DesktopEntries.byId(notif?.desktopEntry ?? "")?.name || ""
    readonly property var otherActions: notif?.actions.filter(a => a.identifier !== "default") ?? []

    function iconSource() {
        if (!notif)
            return "";
        // image can be a path, a URL or an icon name (Ghostty sends "com.mitchellh.ghostty").
        const icon = notif.image || notif.appIcon || notif.desktopEntry;
        if (!icon)
            return "";
        if (icon.startsWith("/"))
            return "file://" + icon;
        if (icon.includes("://"))
            return icon;
        return Quickshell.iconPath(icon, true);
    }

    implicitHeight: content.implicitHeight + 2 * Theme.popupPadding
    radius: Theme.popupRadius
    color: Theme.popupBg
    border.color: critical ? Theme.critical : Theme.popupBorder

    // Click: run the app's default action (e.g. focus its window) if it has one.
    // A toast also closes, staying in the history; the history card stays put.
    MouseArea {
        anchors.fill: parent
        cursorShape: root.defaultAction || root.toast ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            const id = root.notif?.id;
            if (root.defaultAction)
                root.defaultAction.invoke();
            if (root.toast && id !== undefined)
                Notifications.dropToast(id);
        }
    }

    RowLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.popupPadding }
        spacing: 10

        Image {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            Layout.alignment: Qt.AlignTop
            visible: status === Image.Ready
            source: root.iconSource()
            sourceSize: Qt.size(72, 72)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                BarText {
                    Layout.fillWidth: true
                    text: [root.appLabel, Notifications.ago(root.notif?.id ?? -1)].filter(s => s !== "").join(" · ")
                    color: Theme.textMuted
                    font { pixelSize: 11; bold: false }
                    elide: Text.ElideRight
                }

                // ×: dismiss (removes it from the history too).
                Rectangle {
                    implicitWidth: 18
                    implicitHeight: 18
                    radius: 9
                    color: close.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12) : "transparent"

                    BarText {
                        anchors.centerIn: parent
                        text: "✕"
                        color: Theme.textMuted
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: close
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.notif?.dismiss()
                    }
                }
            }

            BarText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notif?.summary ?? ""
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notif?.body ?? ""
                textFormat: Text.StyledText
                color: Theme.textMuted
                linkColor: Theme.accent
                font.pixelSize: 12
                wrapMode: Text.Wrap
                maximumLineCount: root.bodyLines
                elide: Text.ElideRight
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: root.otherActions.length > 0
                spacing: 6

                Repeater {
                    model: root.otherActions

                    Rectangle {
                        required property var modelData
                        implicitWidth: label.implicitWidth + 16
                        implicitHeight: 24
                        radius: 6
                        color: action.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)

                        Behavior on color { ColorAnimation { duration: Theme.animDuration } }

                        BarText {
                            id: label
                            anchors.centerIn: parent
                            text: modelData.text
                            font { pixelSize: 12; bold: false }
                        }

                        MouseArea {
                            id: action
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.invoke()
                        }
                    }
                }
            }
        }
    }
}
