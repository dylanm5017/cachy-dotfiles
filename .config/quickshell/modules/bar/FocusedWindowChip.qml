import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../.." 1.0

Text {
    id: root

    readonly property var activeWindow: Hyprland.activeToplevel

    Layout.alignment: Qt.AlignVCenter
    Layout.maximumWidth: 360

    text: activeWindow && activeWindow.title.length > 0 ? activeWindow.title : "Desktop"
    color: activeWindow && activeWindow.urgent
        ? SmokyPlumTheme.diagnosticError
        : SmokyPlumTheme.textMuted
    elide: Text.ElideRight
    font.pixelSize: 12
    font.weight: Font.Medium
    textFormat: Text.PlainText
    verticalAlignment: Text.AlignVCenter
    wrapMode: Text.NoWrap
}
