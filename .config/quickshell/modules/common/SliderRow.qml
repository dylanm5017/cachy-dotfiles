import QtQuick
import QtQuick.Layouts
import "../.." 1.0

ColumnLayout {
    id: root

    property string label: ""
    property int value: 0

    signal moved(int value)

    Layout.fillWidth: true
    spacing: 6

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true

            text: root.label
            color: SmokyPlumTheme.textSecondary
            font.pixelSize: 11
            font.weight: Font.Medium
            textFormat: Text.PlainText
        }

        Text {
            text: root.value + "%"
            color: SmokyPlumTheme.textPrimary
            font.pixelSize: 11
            font.weight: Font.DemiBold
            textFormat: Text.PlainText
        }
    }

    Rectangle {
        id: track

        Layout.fillWidth: true
        Layout.preferredHeight: 12

        radius: 6
        color: SmokyPlumTheme.surfaceSunken
        border.width: 1
        border.color: SmokyPlumTheme.borderSubtle

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                margins: 1
            }

            width: Math.max(4, (parent.width - 2) * Math.min(100, Math.max(0, root.value)) / 100)
            radius: 5
            color: SmokyPlumTheme.accentRose

            Behavior on width {
                NumberAnimation {
                    duration: Motion.fast
                }
            }
        }

        MouseArea {
            id: drag

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            function applyAt(x) {
                const ratio = Math.min(1, Math.max(0, x / width))
                root.moved(Math.round(ratio * 100))
            }

            onPressed: function(mouse) {
                applyAt(mouse.x)
            }

            onPositionChanged: function(mouse) {
                if (pressed) {
                    applyAt(mouse.x)
                }
            }
        }
    }
}
