import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../.." 1.0
import "../common" 1.0

RowLayout {
    spacing: 2
    Layout.alignment: Qt.AlignVCenter

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            required property var modelData

            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 22
            Layout.preferredWidth: Math.max(22, wsLabel.implicitWidth + 12)

            radius: 7
            color: wsPointer.containsMouse
                ? SmokyPlumTheme.surfaceHover
                : (modelData.focused ? SmokyPlumTheme.accentRose : "transparent")

            Behavior on color {
                ColorAnimation {
                    duration: Motion.fast
                }
            }

            Text {
                id: wsLabel

                anchors.centerIn: parent
                text: modelData.name
                font.pixelSize: 11
                font.weight: modelData.focused ? Font.DemiBold : Font.Medium
                color: modelData.focused
                    ? SmokyPlumTheme.textOnAccent
                    : (modelData.urgent
                        ? SmokyPlumTheme.diagnosticError
                        : (modelData.active ? SmokyPlumTheme.textSecondary : SmokyPlumTheme.textDisabled))

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.fast
                    }
                }
            }

            MouseArea {
                id: wsPointer

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: modelData.activate()
            }
        }
    }
}
