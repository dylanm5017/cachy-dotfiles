import QtQuick
import QtQuick.Layouts
import "../.." 1.0
import "../common" 1.0
import "../../services" 1.0

StatusPill {
    Layout.alignment: Qt.AlignVCenter

    label: AudioStatus.muted ? "Muted" : AudioStatus.volume + "%"
    leadingText: AudioStatus.muted ? "MUTE" : "AUD"
    interactive: true
    fillColor: AudioStatus.muted ? SmokyPlumTheme.diagnosticWarningBackground : SmokyPlumTheme.surfaceActive
    borderColor: AudioStatus.muted ? SmokyPlumTheme.diagnosticWarning : SmokyPlumTheme.borderSubtle
    slotColor: AudioStatus.muted ? SmokyPlumTheme.diagnosticWarningBackground : SmokyPlumTheme.surfaceSunken
    labelColor: AudioStatus.muted ? SmokyPlumTheme.diagnosticWarning : SmokyPlumTheme.textMuted
    leadingColor: AudioStatus.muted ? SmokyPlumTheme.diagnosticWarning : SmokyPlumTheme.textSecondary

    onClicked: AudioStatus.toggleMuted()
}
