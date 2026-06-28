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

    function relativeTime(value) {
        if (!value) {
            return ""
        }

        const diff = Math.max(0, (new Date().getTime() - value.getTime()) / 1000)

        if (diff < 60) {
            return "now"
        }
        if (diff < 3600) {
            return Math.floor(diff / 60) + "m"
        }
        if (diff < 86400) {
            return Math.floor(diff / 3600) + "h"
        }

        return Math.floor(diff / 86400) + "d"
    }

    screen: modelData
    visible: isFocusedScreen && NotificationCenterState.visible
    implicitWidth: 384
    implicitHeight: Math.min(560, surface.implicitHeight)
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

            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: 8
                    color: QuietState.enabled ? SmokyPlumTheme.diagnosticWarningBackground : SmokyPlumTheme.highlightBackground
                    border.width: 1
                    border.color: QuietState.enabled ? SmokyPlumTheme.diagnosticWarning : SmokyPlumTheme.highlightBorder

                    Text {
                        anchors.centerIn: parent
                        text: QuietState.enabled ? "DND" : "BELL"
                        color: QuietState.enabled ? SmokyPlumTheme.diagnosticWarning : SmokyPlumTheme.accentRose
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        textFormat: Text.PlainText
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Notifications"
                        color: SmokyPlumTheme.textPrimary
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        textFormat: Text.PlainText
                    }

                    Text {
                        text: QuietState.enabled
                            ? "Do Not Disturb on"
                            : NotificationState.history.length + " recent"
                        color: SmokyPlumTheme.textMuted
                        font.pixelSize: 9
                        textFormat: Text.PlainText
                    }
                }

                IconButton {
                    label: "clr"
                    fillColor: SmokyPlumTheme.surfaceSunken
                    visible: NotificationState.history.length > 0
                    onClicked: NotificationState.clearHistory()
                }

                IconButton {
                    label: "esc"
                    fillColor: SmokyPlumTheme.surfaceSunken
                    onClicked: NotificationCenterState.close()
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.bottomMargin: 16
                visible: NotificationState.history.length === 0
                horizontalAlignment: Text.AlignHCenter
                text: "No notifications"
                color: SmokyPlumTheme.textMuted
                font.pixelSize: 11
                textFormat: Text.PlainText
            }

            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(440, listColumn.implicitHeight)
                visible: NotificationState.history.length > 0

                clip: true
                contentWidth: width
                contentHeight: listColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: listColumn

                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: NotificationState.history

                        delegate: Rectangle {
                            id: entry

                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: entryLayout.implicitHeight + 18
                            radius: 8
                            color: SmokyPlumTheme.surfaceSunken
                            border.width: 1
                            border.color: entry.modelData.critical ? SmokyPlumTheme.diagnosticError : SmokyPlumTheme.borderSubtle

                            ColumnLayout {
                                id: entryLayout

                                anchors {
                                    fill: parent
                                    margins: 9
                                }

                                spacing: 3

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        Layout.fillWidth: true
                                        text: entry.modelData.appName.length > 0 ? entry.modelData.appName : "System"
                                        color: entry.modelData.critical ? SmokyPlumTheme.diagnosticError : SmokyPlumTheme.accentRose
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                        textFormat: Text.PlainText
                                    }

                                    Text {
                                        text: root.relativeTime(entry.modelData.time)
                                        color: SmokyPlumTheme.textDisabled
                                        font.pixelSize: 9
                                        textFormat: Text.PlainText
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: entry.modelData.summary.length > 0
                                    text: entry.modelData.summary
                                    color: SmokyPlumTheme.textPrimary
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: entry.modelData.body.length > 0
                                    text: entry.modelData.body
                                    color: SmokyPlumTheme.textMuted
                                    font.pixelSize: 10
                                    maximumLineCount: 3
                                    wrapMode: Text.WordWrap
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
