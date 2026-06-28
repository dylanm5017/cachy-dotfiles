import QtQuick
import QtQuick.Layouts
import "../.." 1.0

RowLayout {
    id: root

    property string label: ""
    property string detail: ""
    property color labelColor: SmokyPlumTheme.textMuted
    property color detailColor: SmokyPlumTheme.textDisabled

    Layout.fillWidth: true
    spacing: 8

    Text {
        text: root.label
        color: root.labelColor
        font.pixelSize: 10
        font.weight: Font.DemiBold
        textFormat: Text.PlainText
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: SmokyPlumTheme.borderSubtle
        opacity: 0.7
    }

    Text {
        visible: root.detail.length > 0
        text: root.detail
        color: root.detailColor
        font.pixelSize: 9
        textFormat: Text.PlainText
    }
}
