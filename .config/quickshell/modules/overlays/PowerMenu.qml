import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../.." 1.0
import "../common" 1.0
import "../../services" 1.0

PanelWindow {
    id: root

    required property var modelData
    property bool isFocusedScreen: false

    screen: modelData
    visible: isFocusedScreen && PowerMenuState.visible
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Rectangle {
        anchors.fill: parent
        color: SmokyPlumTheme.baseBackground
        opacity: 0.55

        MouseArea {
            anchors.fill: parent
            onClicked: PowerMenuState.close()
        }
    }

    Rectangle {
        anchors.centerIn: parent

        width: panelContent.implicitWidth + 40
        height: panelContent.implicitHeight + 36
        radius: 14
        color: SmokyPlumTheme.surfaceOverlay
        border.width: 1
        border.color: SmokyPlumTheme.borderStrong

        ColumnLayout {
            id: panelContent

            anchors.centerIn: parent
            spacing: 16

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Session"
                color: SmokyPlumTheme.textPrimary
                font.pixelSize: 15
                font.weight: Font.DemiBold
                textFormat: Text.PlainText
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                Repeater {
                    model: PowerMenuState.actions

                    delegate: Rectangle {
                        id: tile

                        required property var modelData

                        Layout.preferredWidth: 92
                        Layout.preferredHeight: 92
                        radius: 12
                        color: pointer.containsMouse
                            ? (tile.modelData.danger ? SmokyPlumTheme.diagnosticErrorBackground : SmokyPlumTheme.surfaceHover)
                            : SmokyPlumTheme.surfaceActive
                        border.width: 1
                        border.color: pointer.containsMouse
                            ? (tile.modelData.danger ? SmokyPlumTheme.diagnosticError : SmokyPlumTheme.highlightBorder)
                            : SmokyPlumTheme.borderSubtle

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

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 38
                                Layout.preferredHeight: 38
                                radius: 10
                                color: SmokyPlumTheme.surfaceSunken
                                border.width: 1
                                border.color: SmokyPlumTheme.borderSubtle

                                Text {
                                    anchors.centerIn: parent
                                    text: tile.modelData.symbol
                                    color: tile.modelData.danger && pointer.containsMouse
                                        ? SmokyPlumTheme.diagnosticError
                                        : SmokyPlumTheme.accentRose
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    textFormat: Text.PlainText
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: tile.modelData.title
                                color: SmokyPlumTheme.textPrimary
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                textFormat: Text.PlainText
                            }
                        }

                        MouseArea {
                            id: pointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PowerMenuState.run(tile.modelData.key)
                        }
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Esc to cancel"
                color: SmokyPlumTheme.textMuted
                font.pixelSize: 9
                textFormat: Text.PlainText
            }
        }
    }

    Item {
        anchors.fill: parent
        focus: root.visible
        Keys.onEscapePressed: PowerMenuState.close()
    }
}
