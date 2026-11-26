import QtQuick
import qs.config
import qs.services

// Light/dark mode toggle: moon in dark mode, sun in light. See services/ColorMode.qml.
// Not named ColorMode, which is the service singleton.
BarButton {
    icon: ColorMode.dark ? Icons.weatherNight : Icons.whiteBalanceSunny
    onClicked: ColorMode.toggle()
}
