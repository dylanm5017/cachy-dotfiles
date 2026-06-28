import QtQuick
import QtQuick.Layouts
import "../.." 1.0

Text {
    Layout.alignment: Qt.AlignVCenter

    property var now: new Date()

    text: Qt.formatDateTime(now, "HH:mm")
    font.pixelSize: 13
    font.family: "monospace"
    font.weight: Font.Medium
    color: SmokyPlumTheme.textPrimary

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: parent.now = new Date()
    }
}
