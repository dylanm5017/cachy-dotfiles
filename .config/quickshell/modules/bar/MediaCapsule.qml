import QtQuick
import QtQuick.Layouts
import "../.." 1.0
import "../common" 1.0
import "../../services" 1.0

StatusPill {
    Layout.alignment: Qt.AlignVCenter

    visible: MediaStatus.hasPlayer
    leadingText: MediaStatus.isPlaying ? "PLAY" : "PAUSE"
    label: MediaStatus.title
    detail: MediaStatus.artist
    maximumWidth: 230
    interactive: true
    fillColor: MediaStatus.isPlaying ? SmokyPlumTheme.highlightBackground : SmokyPlumTheme.surfaceActive
    borderColor: MediaStatus.isPlaying ? SmokyPlumTheme.highlightBorder : SmokyPlumTheme.borderSubtle
    slotColor: MediaStatus.isPlaying ? SmokyPlumTheme.selectionBackground : SmokyPlumTheme.surfaceSunken
    leadingColor: MediaStatus.isPlaying ? SmokyPlumTheme.accentRose : SmokyPlumTheme.textMuted
    labelColor: MediaStatus.isPlaying ? SmokyPlumTheme.textPrimary : SmokyPlumTheme.textSecondary

    onClicked: MediaPopupState.toggle()
}
