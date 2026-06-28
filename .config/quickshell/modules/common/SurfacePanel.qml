import QtQuick
import "../.." 1.0

Rectangle {
    id: root

    property color fillColor: SmokyPlumTheme.surfaceOverlay
    property color borderColor: SmokyPlumTheme.borderDefault

    radius: 7
    color: fillColor
    border.width: 1
    border.color: borderColor

    Behavior on color {
        ColorAnimation {
            duration: Motion.fast
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Motion.fast
        }
    }
}
