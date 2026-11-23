import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.common

// Muted section heading or hint text inside a popup.
BarText {
    Layout.fillWidth: true
    Layout.leftMargin: 8
    color: Theme.textMuted
    font { pixelSize: 11; bold: false }
    elide: Text.ElideRight
}
