import QtQuick
import QtQuick.Layouts
import "../.." 1.0
import "../common" 1.0
import "../../services" 1.0

Rectangle {
    id: root

    property var now: new Date()
    readonly property string mode: CommandState.visible
        ? "COMMAND"
        : (AudioStatus.osdVisible
            ? "AUDIO"
            : (NotificationState.count > 0
                ? "NOTIFY"
                : (MediaStatus.hasPlayer ? "MEDIA" : "TIME")))
    readonly property bool isMediaMode: mode === "MEDIA"
    readonly property bool isAudioMode: mode === "AUDIO"
    readonly property bool isCommandMode: mode === "COMMAND"
    readonly property bool isNotifyMode: mode === "NOTIFY"
    readonly property string marker: isCommandMode
        ? "ACT"
        : (isAudioMode
            ? (AudioStatus.muted ? "MUTE" : "AUD")
            : (isNotifyMode
                ? "PING"
                : (isMediaMode ? (MediaStatus.isPlaying ? "PLAY" : "PAUSE") : "NOW")))
    readonly property string primaryText: isCommandMode
        ? "Command"
        : (isAudioMode
            ? (AudioStatus.muted ? "Output muted" : "Audio output")
            : (isNotifyMode
                ? "Notifications"
                : (isMediaMode ? MediaStatus.title : Qt.formatDateTime(now, "HH:mm"))))
    readonly property string secondaryText: isCommandMode
        ? CommandState.favoriteEntries.length + " apps / " + ClipboardState.history.length + " clips"
        : (isAudioMode
            ? (AudioStatus.muted ? "0%" : AudioStatus.volume + "%")
            : (isNotifyMode
                ? NotificationState.count + " waiting"
                : (isMediaMode ? MediaStatus.artist : Qt.formatDateTime(now, "ddd d"))))

    signal activated()

    Layout.alignment: Qt.AlignVCenter
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    implicitWidth: isCommandMode ? 278 : (isAudioMode ? 270 : (isMediaMode ? 340 : 156))
    implicitHeight: 34
    radius: 8
    color: isCommandMode
        ? SmokyPlumTheme.highlightBackground
        : (isAudioMode && AudioStatus.muted ? SmokyPlumTheme.diagnosticWarningBackground : SmokyPlumTheme.basePanel)
    border.width: 1
    border.color: isCommandMode
        ? SmokyPlumTheme.highlightBorder
        : (isAudioMode && AudioStatus.muted ? SmokyPlumTheme.diagnosticWarning : SmokyPlumTheme.borderStrong)

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Motion.normal
            easing.type: Easing.OutCubic
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Motion.fast
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 8
            rightMargin: 8
        }

        spacing: 8

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: markerText.implicitWidth + 12
            Layout.preferredHeight: 20

            radius: 6
            color: root.isCommandMode
                ? SmokyPlumTheme.selectionBackground
                : (root.isAudioMode && AudioStatus.muted ? SmokyPlumTheme.diagnosticWarningBackground : SmokyPlumTheme.surfaceActive)
            border.width: 1
            border.color: root.isAudioMode && AudioStatus.muted ? SmokyPlumTheme.diagnosticWarning : SmokyPlumTheme.borderSubtle

            Text {
                id: markerText

                anchors.centerIn: parent

                text: root.marker
                color: root.isAudioMode && AudioStatus.muted ? SmokyPlumTheme.diagnosticWarning : SmokyPlumTheme.accentRose
                font.pixelSize: 8
                font.weight: Font.DemiBold
                textFormat: Text.PlainText
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            RevealText {
                text: root.primaryText
                color: SmokyPlumTheme.textPrimary
                font.pixelSize: root.mode === "TIME" ? 13 : 11
                font.weight: Font.DemiBold
                maximumTextWidth: root.implicitWidth - 112
            }

            RevealText {
                visible: root.secondaryText.length > 0
                text: root.secondaryText
                color: root.isAudioMode && AudioStatus.muted ? SmokyPlumTheme.diagnosticWarning : SmokyPlumTheme.textMuted
                font.pixelSize: 9
                maximumTextWidth: root.implicitWidth - 112
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 8
            Layout.preferredHeight: 8

            radius: 4
            color: root.isMediaMode && MediaStatus.isPlaying
                ? SmokyPlumTheme.diagnosticSuccess
                : (root.isCommandMode || root.isNotifyMode ? SmokyPlumTheme.accentRose : SmokyPlumTheme.borderStrong)
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.isMediaMode) {
                MediaStatus.toggle()
            } else if (root.isAudioMode) {
                AudioStatus.toggleMuted()
            } else if (root.isNotifyMode) {
                NotificationCenterState.toggle()
            } else if (root.isCommandMode) {
                CommandState.toggle()
            } else {
                CalendarState.toggle()
            }

            root.activated()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
}
