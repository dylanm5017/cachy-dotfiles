import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../.." 1.0
import "../common" 1.0
import "../../services" 1.0

PanelWindow {
    id: root

    required property var modelData
    property bool isFocusedScreen: false

    readonly property int panelWidth: 560

    screen: modelData
    visible: isFocusedScreen && CommandState.visible
    implicitWidth: panelWidth
    implicitHeight: Math.min(610, surface.implicitHeight)
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    onVisibleChanged: {
        if (visible) {
            Qt.callLater(function() {
                searchField.forceActiveFocus()
            })
        }
    }

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

        height: root.implicitHeight
        implicitHeight: content.implicitHeight + 28
        radius: 8
        color: SmokyPlumTheme.surfaceOverlay
        border.width: 1
        border.color: SmokyPlumTheme.borderStrong

        Rectangle {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
            }

            width: 96
            height: 3
            radius: 3
            color: SmokyPlumTheme.accentRose
            opacity: 0.85
        }

        ColumnLayout {
            id: content

            anchors {
                fill: parent
                leftMargin: 14
                rightMargin: 14
                topMargin: 14
                bottomMargin: 14
            }

            spacing: 13

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36

                    radius: 8
                    color: SmokyPlumTheme.highlightBackground

                    Text {
                        anchors.centerIn: parent

                        text: "ACT"
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
                        text: "Command"
                        color: SmokyPlumTheme.textPrimary
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        textFormat: Text.PlainText
                    }

                    Text {
                        text: CommandState.favoriteEntries.length + " apps / " + ClipboardState.history.length + " clips"
                        color: SmokyPlumTheme.textMuted
                        font.pixelSize: 9
                        textFormat: Text.PlainText
                    }
                }

                IconButton {
                    label: "esc"
                    fillColor: SmokyPlumTheme.surfaceSunken
                    onClicked: CommandState.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: 8
                color: SmokyPlumTheme.inputBackground
                border.width: 1
                border.color: searchField.activeFocus ? SmokyPlumTheme.borderFocus : SmokyPlumTheme.inputBorder

                Behavior on border.color {
                    ColorAnimation {
                        duration: Motion.fast
                    }
                }

                TextField {
                    id: searchField

                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 12
                    }

                    text: CommandState.query
                    placeholderText: "Search apps…"
                    color: SmokyPlumTheme.textPrimary
                    placeholderTextColor: SmokyPlumTheme.inputPlaceholder
                    font.pixelSize: 12
                    verticalAlignment: TextInput.AlignVCenter
                    background: null

                    onTextChanged: CommandState.query = text
                    onAccepted: CommandState.launchFirstResult()
                    Keys.onEscapePressed: CommandState.close()
                }
            }

            GridLayout {
                Layout.fillWidth: true
                visible: !CommandState.searching
                columns: 5
                columnSpacing: 7
                rowSpacing: 7

                Repeater {
                    model: CommandState.quickActions

                    delegate: Rectangle {
                        id: actionTile

                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: 66

                        radius: 8
                        color: actionPointer.containsMouse ? SmokyPlumTheme.surfaceHover : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: Motion.fast
                            }
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                margins: 8
                            }

                            spacing: 8

                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: 30
                                horizontalAlignment: Text.AlignHCenter

                                text: modelData.symbol
                                color: actionPointer.containsMouse ? SmokyPlumTheme.accentRose : SmokyPlumTheme.textMuted
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                textFormat: Text.PlainText
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 1

                                RevealText {
                                    text: modelData.title
                                    color: SmokyPlumTheme.textPrimary
                                    font.weight: Font.DemiBold
                                    maximumTextWidth: 70
                                }

                                Text {
                                    text: modelData.detail
                                    color: SmokyPlumTheme.textMuted
                                    font.pixelSize: 9
                                    textFormat: Text.PlainText
                                }
                            }
                        }

                        MouseArea {
                            id: actionPointer

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: CommandState.runAction(modelData.key)
                        }
                    }
                }
            }

            Flickable {
                id: scroller

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(380, scrollContent.implicitHeight)

                clip: true
                contentWidth: width
                contentHeight: scrollContent.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: scrollContent

                    width: scroller.width
                    spacing: 14

                    SectionLabel {
                        label: CommandState.searching ? "Results" : "Apps"
                        detail: CommandState.searching
                            ? CommandState.results.length.toString()
                            : CommandState.favoriteEntries.length.toString()
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: CommandState.searching
                        spacing: 3

                        Text {
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            Layout.bottomMargin: 8
                            visible: CommandState.results.length === 0
                            horizontalAlignment: Text.AlignHCenter
                            text: "No matches"
                            color: SmokyPlumTheme.textMuted
                            font.pixelSize: 11
                            textFormat: Text.PlainText
                        }

                        Repeater {
                            model: CommandState.results

                            delegate: ListRow {
                                required property var modelData

                                readonly property string appName: String(modelData.name || "")

                                marker: appName.slice(0, 2).toUpperCase()
                                iconSource: String(modelData.icon || "")
                                label: appName
                                detail: String(modelData.genericName || "")
                                trailing: "run"
                                fillColor: SmokyPlumTheme.surfaceSunken
                                markerFillColor: SmokyPlumTheme.surfaceActive
                                onClicked: CommandState.launch(modelData)
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: !CommandState.searching
                        spacing: 3

                        Repeater {
                            model: CommandState.favoriteEntries

                            delegate: ListRow {
                                required property var modelData

                                readonly property string appName: String(modelData.name || "")

                                marker: appName.slice(0, 2).toUpperCase()
                                iconSource: String(modelData.icon || "")
                                label: appName
                                detail: String(modelData.genericName || "")
                                trailing: "run"
                                fillColor: SmokyPlumTheme.surfaceSunken
                                markerFillColor: SmokyPlumTheme.surfaceActive
                                onClicked: CommandState.launch(modelData)
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: !CommandState.searching && ClipboardState.history.length > 0
                        spacing: 3

                        SectionLabel {
                            label: "Clipboard"
                            detail: ClipboardState.history.length.toString()
                        }

                        Repeater {
                            model: ClipboardState.history

                            delegate: ListRow {
                                required property string modelData

                                marker: "CL"
                                label: ClipboardState.previewText(modelData)
                                trailing: "copy"
                                fillColor: SmokyPlumTheme.surfaceSunken
                                markerFillColor: SmokyPlumTheme.highlightBackground
                                markerColor: SmokyPlumTheme.accentCool
                                onClicked: {
                                    ClipboardState.copy(modelData)
                                    CommandState.close()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
