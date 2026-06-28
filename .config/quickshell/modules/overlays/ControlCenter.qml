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
    visible: isFocusedScreen && ControlCenterState.visible
    implicitWidth: 348
    implicitHeight: Math.min(540, surface.implicitHeight)
    color: "transparent"
    exclusiveZone: 0

    anchors {
        top: true
        right: true
    }

    margins {
        top: 54
        right: 12
    }

    Rectangle {
        id: surface

        anchors {
            right: parent.right
            top: parent.top
        }

        width: parent.width
        height: root.implicitHeight
        implicitHeight: content.implicitHeight + 28
        radius: 10
        color: SmokyPlumTheme.surfaceOverlay
        border.width: 1
        border.color: SmokyPlumTheme.borderStrong

        ColumnLayout {
            id: content

            anchors {
                fill: parent
                margins: 14
            }

            spacing: 13

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36

                    radius: 8
                    color: SmokyPlumTheme.highlightBackground

                    Text {
                        anchors.centerIn: parent

                        text: "SET"
                        color: SmokyPlumTheme.accentRose
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        textFormat: Text.PlainText
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Control"
                        color: SmokyPlumTheme.textPrimary
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        textFormat: Text.PlainText
                    }

                    Text {
                        Layout.fillWidth: true

                        text: NetworkStatus.label
                            + (BluetoothStatus.connected ? "  ·  " + BluetoothStatus.connectedDevice : "")
                        color: SmokyPlumTheme.textMuted
                        font.pixelSize: 9
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                }

                IconButton {
                    label: "esc"
                    fillColor: SmokyPlumTheme.surfaceSunken
                    onClicked: ControlCenterState.close()
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                ToggleTile {
                    marker: "WIFI"
                    title: "Wi-Fi"
                    state: NetworkStatus.wifiEnabled
                        ? (NetworkStatus.kind === "wifi" ? NetworkStatus.label : "On")
                        : "Off"
                    active: NetworkStatus.wifiEnabled
                    onClicked: NetworkStatus.toggleWifi()
                }

                ToggleTile {
                    marker: "BT"
                    title: "Bluetooth"
                    state: BluetoothStatus.powered
                        ? (BluetoothStatus.connected ? BluetoothStatus.connectedDevice : "On")
                        : "Off"
                    active: BluetoothStatus.powered
                    onClicked: BluetoothStatus.togglePowered()
                }

                ToggleTile {
                    marker: AudioStatus.muted ? "MUTE" : "AUD"
                    title: "Audio"
                    state: AudioStatus.muted ? "Muted" : AudioStatus.volume + "%"
                    active: !AudioStatus.muted
                    onClicked: AudioStatus.toggleMuted()
                }

                ToggleTile {
                    marker: "DND"
                    title: "Do Not Disturb"
                    state: QuietState.enabled ? "Silencing" : "Off"
                    active: QuietState.enabled
                    onClicked: QuietState.toggle()
                }
            }

            SliderRow {
                label: "Volume"
                value: AudioStatus.volume
                onMoved: v => AudioStatus.setVolume(v)
            }
        }
    }
}
