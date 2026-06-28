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

    property var viewDate: new Date()
    property var now: new Date()

    readonly property var cells: buildCells(viewDate, now)

    function buildCells(view, today) {
        const year = view.getFullYear()
        const month = view.getMonth()
        const first = new Date(year, month, 1).getDay()
        const days = new Date(year, month + 1, 0).getDate()
        const result = []

        for (let i = 0; i < 42; i += 1) {
            const dayNum = i - first + 1

            if (dayNum < 1 || dayNum > days) {
                result.push({ day: "", today: false })
            } else {
                const isToday = dayNum === today.getDate()
                    && month === today.getMonth()
                    && year === today.getFullYear()
                result.push({ day: String(dayNum), today: isToday })
            }
        }

        return result
    }

    function shiftMonth(delta) {
        const next = new Date(viewDate)
        next.setDate(1)
        next.setMonth(next.getMonth() + delta)
        viewDate = next
    }

    function resetToToday() {
        viewDate = new Date()
    }

    readonly property int panelWidth: 312

    screen: modelData
    visible: isFocusedScreen && CalendarState.visible
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

    onVisibleChanged: {
        if (visible) {
            now = new Date()
            resetToToday()
        }
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
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: Qt.formatDateTime(root.now, "dddd")
                        color: SmokyPlumTheme.accentRose
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        textFormat: Text.PlainText
                    }

                    Text {
                        text: Qt.formatDateTime(root.now, "d MMMM yyyy")
                        color: SmokyPlumTheme.textPrimary
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        textFormat: Text.PlainText
                    }
                }

                IconButton {
                    label: "‹"
                    fillColor: SmokyPlumTheme.surfaceSunken
                    onClicked: root.shiftMonth(-1)
                }

                IconButton {
                    label: "•"
                    fillColor: SmokyPlumTheme.surfaceSunken
                    onClicked: root.resetToToday()
                }

                IconButton {
                    label: "›"
                    fillColor: SmokyPlumTheme.surfaceSunken
                    onClicked: root.shiftMonth(1)
                }
            }

            Text {
                text: Qt.formatDate(root.viewDate, "MMMM yyyy")
                color: SmokyPlumTheme.textSecondary
                font.pixelSize: 11
                font.weight: Font.Medium
                textFormat: Text.PlainText
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 4
                columnSpacing: 0

                Repeater {
                    model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

                    delegate: Text {
                        required property string modelData

                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: SmokyPlumTheme.textMuted
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        textFormat: Text.PlainText
                    }
                }

                Repeater {
                    model: root.cells

                    delegate: Item {
                        id: cell

                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: 30

                        Rectangle {
                            anchors.centerIn: parent
                            width: 26
                            height: 26
                            radius: 7
                            visible: cell.modelData.day.length > 0
                            color: cell.modelData.today ? SmokyPlumTheme.highlightBackground : "transparent"
                            border.width: cell.modelData.today ? 1 : 0
                            border.color: SmokyPlumTheme.highlightBorder

                            Text {
                                anchors.centerIn: parent
                                text: cell.modelData.day
                                color: cell.modelData.today
                                    ? SmokyPlumTheme.accentRose
                                    : SmokyPlumTheme.textSecondary
                                font.pixelSize: 10
                                font.weight: cell.modelData.today ? Font.DemiBold : Font.Normal
                                textFormat: Text.PlainText
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        interval: 30000
        running: root.visible
        repeat: true
        onTriggered: root.now = new Date()
    }
}
