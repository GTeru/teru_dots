import QtQuick
import qs.config
import qs.services

// Weather icon + temperature, e.g. "🌦️ 28°C". Click to refresh.
Text {
    visible: Weather.ready
    text: `${Weather.icon} ${Weather.temperature}`
    color: Theme.text
    font { pixelSize: 13; bold: true }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Weather.refresh()
    }
}
