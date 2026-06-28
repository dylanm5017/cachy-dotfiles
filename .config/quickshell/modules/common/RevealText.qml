import QtQuick
import QtQuick.Layouts
import "../.." 1.0

Text {
    id: root

    property int maximumTextWidth: 180
    property bool fill: true

    Layout.fillWidth: fill
    Layout.maximumWidth: maximumTextWidth

    color: SmokyPlumTheme.textSecondary
    elide: Text.ElideRight
    font.pixelSize: 11
    horizontalAlignment: Text.AlignLeft
    textFormat: Text.PlainText
    verticalAlignment: Text.AlignVCenter
    wrapMode: Text.NoWrap

    Behavior on opacity {
        NumberAnimation {
            duration: Motion.normal
        }
    }
}
