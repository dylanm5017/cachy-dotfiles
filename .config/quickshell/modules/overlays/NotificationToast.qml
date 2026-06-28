import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import Quickshell.Widgets
import "../.." 1.0
import "../common" 1.0

Rectangle {
    id: root

    required property var notification
    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property string sourceName: plain(notification.appName || notification.desktopEntry || "Shell")
    readonly property string summaryText: plain(notification.summary || "Notification")
    readonly property string bodyText: plain(notification.body)
    readonly property string iconSource: resolveIconSource(notification.image).length > 0
        ? resolveIconSource(notification.image)
        : resolveIconSource(notification.appIcon)
    readonly property string markerText: sourceName.slice(0, 2).toUpperCase()

    function plain(value) {
        return String(value || "").replace(/<[^>]*>/g, "")
    }

    function usableIconSource(source) {
        const value = String(source || "")

        return value.indexOf("/") === 0
            || value.indexOf("file:") === 0
            || value.indexOf("image:") === 0
            || value.indexOf("qrc:") === 0
    }

    function resolveIconSource(source) {
        const value = String(source || "")

        if (!usableIconSource(value)) {
            return ""
        }

        return value.indexOf("/") === 0 ? "file://" + value : value
    }

    Layout.fillWidth: true
    Layout.preferredHeight: Math.max(88, content.implicitHeight + 20)

    radius: 7
    color: critical ? SmokyPlumTheme.diagnosticErrorBackground : SmokyPlumTheme.surfaceOverlay
    border.width: 1
    border.color: critical ? SmokyPlumTheme.diagnosticError : SmokyPlumTheme.borderDefault

    Behavior on color {
        ColorAnimation {
            duration: Motion.fast
        }
    }

    Timer {
        interval: notification.expireTimeout > 0 ? notification.expireTimeout : 6500
        running: !notification.resident
        onTriggered: notification.dismiss()
    }

    RowLayout {
        id: content

        anchors {
            fill: parent
            margins: 10
        }

        spacing: 10

        Rectangle {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 3
            Layout.fillHeight: true

            radius: 2
            color: critical ? SmokyPlumTheme.diagnosticError : SmokyPlumTheme.accentRose
        }

        Rectangle {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36

            radius: 7
            color: critical ? SmokyPlumTheme.diagnosticErrorBackground : SmokyPlumTheme.surfaceActive
            border.width: 1
            border.color: critical ? SmokyPlumTheme.diagnosticError : SmokyPlumTheme.borderSubtle

            IconImage {
                id: notificationIcon

                anchors.centerIn: parent

                visible: root.iconSource.length > 0 && status !== Image.Error
                source: root.iconSource
                asynchronous: true
                implicitSize: 22
                width: 22
                height: 22
            }

            Text {
                anchors.centerIn: parent

                visible: !notificationIcon.visible
                text: root.markerText
                color: critical ? SmokyPlumTheme.diagnosticError : SmokyPlumTheme.accentCool
                font.pixelSize: 9
                font.weight: Font.DemiBold
                textFormat: Text.PlainText
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: root.sourceName
                        color: critical ? SmokyPlumTheme.diagnosticError : SmokyPlumTheme.textMuted
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        textFormat: Text.PlainText
                    }

                    RevealText {
                        text: root.summaryText
                        color: SmokyPlumTheme.textPrimary
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        maximumTextWidth: 250
                    }
                }

                IconButton {
                    label: "x"
                    fillColor: critical ? SmokyPlumTheme.diagnosticErrorBackground : SmokyPlumTheme.surfaceSunken
                    borderColor: critical ? SmokyPlumTheme.diagnosticError : SmokyPlumTheme.borderSubtle
                    foreground: critical ? SmokyPlumTheme.diagnosticError : SmokyPlumTheme.textMuted
                    onClicked: notification.dismiss()
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0

                text: root.bodyText
                color: SmokyPlumTheme.textSecondary
                elide: Text.ElideRight
                font.pixelSize: 11
                maximumLineCount: 2
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
            }

            RowLayout {
                visible: notification.actions.length > 0
                spacing: 6

                Repeater {
                    model: notification.actions

                    delegate: StatusPill {
                        required property var modelData

                        label: modelData.text
                        maximumWidth: 140
                        interactive: true
                        fillColor: critical ? SmokyPlumTheme.diagnosticErrorBackground : SmokyPlumTheme.surfaceActive
                        borderColor: critical ? SmokyPlumTheme.diagnosticError : SmokyPlumTheme.borderSubtle
                        labelColor: SmokyPlumTheme.textSecondary
                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }
}
