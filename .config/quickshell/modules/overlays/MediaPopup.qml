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

    function fmt(seconds) {
        if (!seconds || seconds < 0) {
            return "0:00"
        }

        const total = Math.floor(seconds)
        const mins = Math.floor(total / 60)
        const secs = total % 60

        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    readonly property int panelWidth: 380

    screen: modelData
    visible: isFocusedScreen && MediaPopupState.visible && MediaStatus.hasPlayer
    implicitWidth: panelWidth
    implicitHeight: surface.implicitHeight
    color: "transparent"
    exclusiveZone: 0

    anchors {
        top: true
        left: true
    }

    margins {
        top: 54
        left: Math.max(12, (modelData.width - panelWidth) / 2)
    }

    Rectangle {
        id: surface

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        implicitHeight: layout.implicitHeight + 28
        radius: 10
        color: SmokyPlumTheme.surfaceOverlay
        border.width: 1
        border.color: SmokyPlumTheme.borderStrong

        ColumnLayout {
            id: layout

            anchors {
                fill: parent
                margins: 14
            }

            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    radius: 8
                    color: SmokyPlumTheme.surfaceSunken
                    border.width: 1
                    border.color: SmokyPlumTheme.borderSubtle
                    clip: true

                    Image {
                        id: art
                        anchors.fill: parent
                        source: MediaStatus.artUrl
                        visible: MediaStatus.artUrl.length > 0 && status === Image.Ready
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 128
                        sourceSize.height: 128
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !art.visible
                        text: "♪"
                        color: SmokyPlumTheme.accentRose
                        font.pixelSize: 24
                        textFormat: Text.PlainText
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 3

                    Text {
                        Layout.fillWidth: true
                        text: MediaStatus.title
                        color: SmokyPlumTheme.textPrimary
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: MediaStatus.artist.length > 0
                        text: MediaStatus.artist
                        color: SmokyPlumTheme.textMuted
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                }

                IconButton {
                    label: "esc"
                    fillColor: SmokyPlumTheme.surfaceSunken
                    onClicked: MediaPopupState.close()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: MediaStatus.length > 0
                spacing: 8

                Text {
                    text: root.fmt(MediaStatus.position)
                    color: SmokyPlumTheme.textMuted
                    font.pixelSize: 9
                    textFormat: Text.PlainText
                }

                Rectangle {
                    id: track
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
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
                        width: MediaStatus.length > 0
                            ? Math.max(0, (parent.width - 2) * Math.min(1, MediaStatus.position / MediaStatus.length))
                            : 0
                        radius: 3
                        color: SmokyPlumTheme.accentRose

                        Behavior on width {
                            NumberAnimation {
                                duration: Motion.normal
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: MediaStatus.canSeek
                        cursorShape: MediaStatus.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: mouse => MediaStatus.seekFraction(mouse.x / width)
                    }
                }

                Text {
                    text: root.fmt(MediaStatus.length)
                    color: SmokyPlumTheme.textMuted
                    font.pixelSize: 9
                    textFormat: Text.PlainText
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                IconButton {
                    label: "‹‹"
                    enabled: MediaStatus.canGoPrevious
                    onClicked: MediaStatus.previous()
                }

                Rectangle {
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 30
                    radius: 8
                    color: playPointer.containsMouse ? SmokyPlumTheme.surfaceHover : SmokyPlumTheme.highlightBackground
                    border.width: 1
                    border.color: SmokyPlumTheme.highlightBorder

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.fast
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: MediaStatus.isPlaying ? "pause" : "play"
                        color: SmokyPlumTheme.accentRose
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        textFormat: Text.PlainText
                    }

                    MouseArea {
                        id: playPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MediaStatus.toggle()
                    }
                }

                IconButton {
                    label: "››"
                    enabled: MediaStatus.canGoNext
                    onClicked: MediaStatus.next()
                }
            }
        }
    }
}
