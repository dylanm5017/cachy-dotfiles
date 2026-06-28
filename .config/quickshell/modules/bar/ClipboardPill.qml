import QtQuick
import QtQuick.Layouts
import "../.." 1.0
import "../common" 1.0
import "../../services" 1.0

StatusPill {
    Layout.alignment: Qt.AlignVCenter

    visible: ClipboardState.hasText
    leadingText: "CLIP"
    label: ClipboardState.preview
    maximumWidth: 130
    interactive: true
    fillColor: CommandState.visible ? SmokyPlumTheme.highlightBackground : SmokyPlumTheme.surfaceActive
    borderColor: CommandState.visible ? SmokyPlumTheme.highlightBorder : SmokyPlumTheme.borderSubtle
    slotColor: CommandState.visible ? SmokyPlumTheme.selectionBackground : SmokyPlumTheme.surfaceSunken
    labelColor: SmokyPlumTheme.textMuted
    leadingColor: SmokyPlumTheme.textSecondary

    onClicked: CommandState.toggle()
}
