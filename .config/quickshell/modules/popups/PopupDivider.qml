import QtQuick
import QtQuick.Layouts
import qs.config

// Thin line between popup sections.
Rectangle {
    Layout.fillWidth: true
    Layout.topMargin: 2
    Layout.bottomMargin: 2
    implicitHeight: 1
    color: Theme.popupBorder
}
