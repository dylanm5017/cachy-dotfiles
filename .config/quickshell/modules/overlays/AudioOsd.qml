import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.." 1.0
import "../common" 1.0
import "../../services" 1.0

PanelWindow {
    id: root

    required property var modelData
    property bool isFocusedScreen: false

    screen: modelData
    visible: isFocusedScreen && AudioStatus.osdVisible && !CommandState.visible
    implicitHeight: 74
    color: "transparent"
    exclusiveZone: 0

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: 56
    }

    Rectangle {
        id: surface

        readonly property real level: Math.min(AudioStatus.volume, 100) / 100

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
        }

        width: 302
        height: parent.height
        radius: 8
        color: AudioStatus.muted ? SmokyPlumTheme.diagnosticWarningBackground : SmokyPlumTheme.surfaceOverlay
        border.width: 1
        border.color: AudioStatus.muted ? SmokyPlumTheme.diagnosticWarning : SmokyPlumTheme.borderStrong

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

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 12
                rightMargin: 12
            }

            spacing: 12

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42

                radius: 8
                color: AudioStatus.muted ? SmokyPlumTheme.diagnosticWarningBackground : SmokyPlumTheme.highlightBackground
                border.width: 1
                border.color: AudioStatus.muted ? SmokyPlumTheme.diagnosticWarning : SmokyPlumTheme.highlightBorder

                Text {
                    anchors.centerIn: parent

                    text: AudioStatus.muted ? "MUTE" : "AUD"
                    color: AudioStatus.muted ? SmokyPlumTheme.diagnosticWarning : SmokyPlumTheme.accentRose
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    textFormat: Text.PlainText
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 7

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true

                        text: AudioStatus.muted ? "Output muted" : "Audio output"
                        color: SmokyPlumTheme.textSecondary
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        textFormat: Text.PlainText
                    }

                    Text {
                        text: AudioStatus.muted ? "0%" : AudioStatus.volume + "%"
                        color: AudioStatus.muted ? SmokyPlumTheme.diagnosticWarning : SmokyPlumTheme.textPrimary
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        textFormat: Text.PlainText
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 7

                    radius: 4
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

                        width: AudioStatus.muted ? 0 : Math.max(4, (parent.width - 2) * surface.level)
                        radius: 3
                        color: AudioStatus.muted ? SmokyPlumTheme.diagnosticWarning : SmokyPlumTheme.accentRose

                        Behavior on width {
                            NumberAnimation {
                                duration: Motion.normal
                            }
                        }
                    }
                }
            }
        }
    }
}
