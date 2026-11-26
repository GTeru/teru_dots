import QtQuick
import qs.config
import qs.services
import qs.modules.common

// Weather icon + temperature, e.g. "28°C" after a rain cloud. Click to refresh.
Item {
    visible: Weather.ready
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: 4

        IconText {
            anchors.verticalCenter: parent.verticalCenter
            text: Weather.icon
        }
        BarText {
            anchors.verticalCenter: parent.verticalCenter
            text: Weather.temperature
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Weather.refresh()
    }
}
