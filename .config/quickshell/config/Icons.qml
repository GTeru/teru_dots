pragma Singleton

import Quickshell
import QtQuick

// Icon glyphs from FiraCode Nerd Font (ttf-firacode-nerd in install.sh), drawn with
// modules/common/IconText.qml: `IconText { text: Icons.wifi }`. Each name is the
// camelCase of a Material Design Icons glyph in the font (`volumeHigh` is
// md-volume_high); search https://www.nerdfonts.com/cheat-sheet for "md-" names
// to add more, and check the codepoint there.
Singleton {
    readonly property string family: "FiraCode Nerd Font Propo"

    // Bar
    readonly property string music: String.fromCodePoint(0xf075a)
    readonly property string lan: String.fromCodePoint(0xf0317)
    readonly property string wifi: String.fromCodePoint(0xf05a9)
    readonly property string wifiOff: String.fromCodePoint(0xf05aa)
    readonly property string bluetooth: String.fromCodePoint(0xf00af)
    readonly property string bluetoothOff: String.fromCodePoint(0xf00b2)
    readonly property string bluetoothConnect: String.fromCodePoint(0xf00b1)
    readonly property string volumeOff: String.fromCodePoint(0xf0581)
    readonly property string volumeLow: String.fromCodePoint(0xf057f)
    readonly property string volumeMedium: String.fromCodePoint(0xf0580)
    readonly property string volumeHigh: String.fromCodePoint(0xf057e)
    readonly property string battery: String.fromCodePoint(0xf0079)
    readonly property string batteryCharging: String.fromCodePoint(0xf0084)
    readonly property string batteryAlert: String.fromCodePoint(0xf0083)
    readonly property string bellOutline: String.fromCodePoint(0xf009c)
    readonly property string bellBadge: String.fromCodePoint(0xf116b)
    readonly property string bellOff: String.fromCodePoint(0xf009b)
    readonly property string weatherNight: String.fromCodePoint(0xf0594)
    readonly property string whiteBalanceSunny: String.fromCodePoint(0xf05a8)
    readonly property string chevronLeft: String.fromCodePoint(0xf0141)

    // Popups and launcher
    readonly property string skipPrevious: String.fromCodePoint(0xf04ae)
    readonly property string pause: String.fromCodePoint(0xf03e4)
    readonly property string play: String.fromCodePoint(0xf040a)
    readonly property string skipNext: String.fromCodePoint(0xf04ad)
    readonly property string microphone: String.fromCodePoint(0xf036c)
    readonly property string microphoneOff: String.fromCodePoint(0xf036d)
    readonly property string leaf: String.fromCodePoint(0xf032a)
    readonly property string scaleBalance: String.fromCodePoint(0xf05d1)
    readonly property string rocketLaunch: String.fromCodePoint(0xf14de)
    readonly property string lock: String.fromCodePoint(0xf033e)
    readonly property string close: String.fromCodePoint(0xf0156)
    readonly property string magnify: String.fromCodePoint(0xf0349)

    // Weather (services/Weather.qml)
    readonly property string weatherSunny: String.fromCodePoint(0xf0599)
    readonly property string weatherPartlyCloudy: String.fromCodePoint(0xf0595)
    readonly property string weatherCloudy: String.fromCodePoint(0xf0590)
    readonly property string weatherFog: String.fromCodePoint(0xf0591)
    readonly property string weatherRainy: String.fromCodePoint(0xf0597)
    readonly property string weatherPouring: String.fromCodePoint(0xf0596)
    readonly property string weatherSnowyRainy: String.fromCodePoint(0xf067f)
    readonly property string weatherSnowy: String.fromCodePoint(0xf0598)
    readonly property string weatherSnowyHeavy: String.fromCodePoint(0xf0f36)
    readonly property string weatherLightningRainy: String.fromCodePoint(0xf067e)
    readonly property string weatherLightning: String.fromCodePoint(0xf0593)
    readonly property string weatherCloudyAlert: String.fromCodePoint(0xf0f2f)
}
