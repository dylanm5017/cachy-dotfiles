import QtQuick
import QtQuick.Controls
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
    property string query: ""

    readonly property var filtered: filterBinds(CheatsheetState.binds, query)

    function filterBinds(binds, text) {
        const needle = String(text || "").trim().toLowerCase()

        if (needle.length === 0) {
            return binds
        }

        const out = []

        for (let i = 0; i < binds.length; i += 1) {
            const bind = binds[i]
            const hay = (bind.mods + " " + bind.key + " " + bind.action).toLowerCase()

            if (hay.indexOf(needle) !== -1) {
                out.push(bind)
            }
        }

        return out
    }

    screen: modelData
    visible: isFocusedScreen && CheatsheetState.visible
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    onVisibleChanged: {
        if (visible) {
            query = ""
            Qt.callLater(function() {
                cheatSearch.forceActiveFocus()
            })
        }
    }

    Rectangle {
        anchors.fill: parent
        color: SmokyPlumTheme.baseBackground
        opacity: 0.55

        MouseArea {
            anchors.fill: parent
            onClicked: CheatsheetState.close()
        }
    }

    Rectangle {
        anchors.centerIn: parent

        width: 720
        height: Math.min(parent.height - 140, 760)
        radius: 12
        color: SmokyPlumTheme.surfaceOverlay
        border.width: 1
        border.color: SmokyPlumTheme.borderStrong

        ColumnLayout {
            id: panelContent

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
                    color: SmokyPlumTheme.highlightBackground

                    Text {
                        anchors.centerIn: parent
                        text: "KEY"
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
                        text: "Keybindings"
                        color: SmokyPlumTheme.textPrimary
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        textFormat: Text.PlainText
                    }

                    Text {
                        text: root.filtered.length + " of " + CheatsheetState.binds.length
                        color: SmokyPlumTheme.textMuted
                        font.pixelSize: 9
                        textFormat: Text.PlainText
                    }
                }

                IconButton {
                    label: "esc"
                    fillColor: SmokyPlumTheme.surfaceSunken
                    onClicked: CheatsheetState.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 8
                color: SmokyPlumTheme.inputBackground
                border.width: 1
                border.color: cheatSearch.activeFocus ? SmokyPlumTheme.borderFocus : SmokyPlumTheme.inputBorder

                TextField {
                    id: cheatSearch

                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 12
                    }

                    text: root.query
                    placeholderText: "Filter shortcuts…"
                    color: SmokyPlumTheme.textPrimary
                    placeholderTextColor: SmokyPlumTheme.inputPlaceholder
                    font.pixelSize: 12
                    verticalAlignment: TextInput.AlignVCenter
                    background: null

                    onTextChanged: root.query = text
                    Keys.onEscapePressed: CheatsheetState.close()
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true

                clip: true
                contentWidth: width
                contentHeight: grid.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                GridLayout {
                    id: grid

                    width: parent.width
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 6

                    Repeater {
                        model: root.filtered

                        delegate: Rectangle {
                            id: bindRow

                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            radius: 7
                            color: "transparent"

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 9
                                    rightMargin: 9
                                }

                                spacing: 8

                                Rectangle {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredWidth: comboText.implicitWidth + 14
                                    Layout.preferredHeight: 20
                                    radius: 5
                                    color: SmokyPlumTheme.highlightBackground

                                    Text {
                                        id: comboText
                                        anchors.centerIn: parent
                                        text: bindRow.modelData.mods.length > 0
                                            ? bindRow.modelData.mods + " + " + bindRow.modelData.key
                                            : bindRow.modelData.key
                                        color: SmokyPlumTheme.accentRose
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                        textFormat: Text.PlainText
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: bindRow.modelData.action
                                    color: SmokyPlumTheme.textSecondary
                                    font.pixelSize: 10
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

    Item {
        anchors.fill: parent
        focus: root.visible
        Keys.onEscapePressed: CheatsheetState.close()
    }
}
