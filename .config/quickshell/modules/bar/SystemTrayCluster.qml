import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../.." 1.0
import "../common" 1.0

RowLayout {
    id: root

    property var panelWindow

    visible: SystemTray.items.values.length > 0
    spacing: 3
    Layout.alignment: Qt.AlignVCenter

    Repeater {
        model: SystemTray.items

        delegate: Rectangle {
            id: trayItem

            required property var modelData

            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22

            radius: 5
            color: trayPointer.containsMouse
                ? SmokyPlumTheme.surfaceHover
                : (modelData.status === Status.NeedsAttention ? SmokyPlumTheme.diagnosticWarningBackground : SmokyPlumTheme.surfaceSunken)
            border.width: 1
            border.color: modelData.status === Status.NeedsAttention ? SmokyPlumTheme.diagnosticWarning : SmokyPlumTheme.borderSubtle
            opacity: modelData.status === Status.Passive ? 0.55 : 1

            Behavior on color {
                ColorAnimation {
                    duration: Motion.fast
                }
            }

            IconImage {
                anchors.centerIn: parent

                implicitSize: 15
                width: 15
                height: 15
                source: modelData.icon
                asynchronous: true
            }

            MouseArea {
                id: trayPointer

                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: function(mouse) {
                    const position = trayItem.mapToItem(null, trayItem.width / 2, trayItem.height)

                    if ((mouse.button === Qt.RightButton || modelData.onlyMenu) && modelData.hasMenu) {
                        modelData.display(root.panelWindow, position.x, position.y)
                    } else {
                        modelData.activate()
                    }
                }
            }
        }
    }
}
