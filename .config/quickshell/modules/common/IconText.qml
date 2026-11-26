import QtQuick
import qs.config

// One icon glyph from config/Icons.qml, e.g. `IconText { text: Icons.wifi }`.
// Colored like text, so it follows the theme.
Text {
    color: Theme.text
    font { family: Icons.family; pixelSize: Theme.iconSize }
    verticalAlignment: Text.AlignVCenter
}
