import QtQuick
import qs.config

// Text styled like the rest of the bar. Base for the right-side indicators.
Text {
    color: Theme.text
    // Tabular digits: changing numbers (clock seconds, percentages) keep their width.
    font { pixelSize: Theme.fontSize; bold: true; features: { "tnum": 1 } }
    verticalAlignment: Text.AlignVCenter
}
