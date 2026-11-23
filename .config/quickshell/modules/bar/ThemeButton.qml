import QtQuick
import qs.services

// Light/dark mode toggle: 🌙 in dark mode, ☀️ in light. See services/ColorMode.qml.
// Not named ColorMode, which is the service singleton.
BarButton {
    label: ColorMode.dark ? "🌙" : "☀️"
    onClicked: ColorMode.toggle()
}
