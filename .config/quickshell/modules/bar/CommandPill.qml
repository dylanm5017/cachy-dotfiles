import QtQuick
import QtQuick.Layouts
import "../.." 1.0
import "../common" 1.0
import "../../services" 1.0

StatusPill {
    Layout.alignment: Qt.AlignVCenter

    leadingText: "ACT"
    label: CommandState.visible ? "open" : "menu"
    maximumWidth: 92
    interactive: true
    fillColor: CommandState.visible ? SmokyPlumTheme.highlightBackground : SmokyPlumTheme.surfaceActive
    borderColor: CommandState.visible ? SmokyPlumTheme.highlightBorder : SmokyPlumTheme.borderSubtle
    slotColor: CommandState.visible ? SmokyPlumTheme.selectionBackground : SmokyPlumTheme.surfaceSunken
    leadingColor: CommandState.visible ? SmokyPlumTheme.accentRose : SmokyPlumTheme.textMuted
    labelColor: CommandState.visible ? SmokyPlumTheme.textPrimary : SmokyPlumTheme.textSecondary

    onClicked: CommandState.toggle()
}
