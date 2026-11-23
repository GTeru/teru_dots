import QtQuick
import qs.config

// Small analog clock for `hour`:`minute` (24h). Dimmed at night (before 6:00,
// from 18:00). Used by ClockPopup.
Rectangle {
    id: face
    property int hour
    property int minute
    readonly property bool night: hour < 6 || hour >= 18
    readonly property real r: width / 2

    implicitWidth: 64
    implicitHeight: 64
    radius: r
    // Brighter face by day, in either mode.
    color: night ? (Theme.dark ? Theme.bg : Theme.popupHover) : (Theme.dark ? Theme.bgHover : Theme.bg)
    border { width: 2; color: night ? Theme.popupBorder : Theme.accentDim }

    Behavior on color { ColorAnimation { duration: Theme.animDuration } }

    // Hour ticks.
    Repeater {
        model: 12
        Rectangle {
            required property int index
            x: face.r - width / 2
            y: 4
            width: index % 3 === 0 ? 2 : 1
            height: index % 3 === 0 ? 5 : 3
            color: Theme.fgMuted
            transformOrigin: Item.Top
            transform: Rotation { origin.x: width / 2; origin.y: face.r - 4; angle: index * 30 }
        }
    }

    Hand {   // hour
        r: face.r
        width: 3
        length: face.r * 0.5
        handAngle: (face.hour % 12) * 30 + face.minute * 0.5
        color: Theme.text
    }
    Hand {   // minute
        r: face.r
        width: 2
        length: face.r * 0.78
        handAngle: face.minute * 6
        color: Theme.accent
    }
    Rectangle {   // hub
        width: 6; height: 6; radius: 3
        anchors.centerIn: parent
        color: Theme.accent
    }

    // A clock hand pivoting on the face's center (`r` = face radius).
    component Hand: Rectangle {
        id: hand
        property real r
        property real length
        property real handAngle
        x: r - width / 2
        y: r - length
        height: length
        radius: width / 2
        antialiasing: true
        transform: Rotation { origin.x: hand.width / 2; origin.y: hand.length; angle: hand.handAngle }
    }
}
