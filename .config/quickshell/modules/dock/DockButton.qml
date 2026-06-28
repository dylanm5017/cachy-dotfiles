import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../.." 1.0
import "../common" 1.0

Rectangle {
    id: root

    property string label: ""
    property string detail: ""
    property string marker: ""
    property string iconSource: ""
    property bool emphasized: false
    property bool running: false
    readonly property string resolvedIconSource: resolveIconSource(iconSource)

    signal clicked()

    function usableIconSource(source) {
        const value = String(source || "")

        return value.indexOf("/") === 0
            || value.indexOf("file:") === 0
            || value.indexOf("image:") === 0
            || value.indexOf("qrc:") === 0
    }

    function resolveIconSource(source) {
        const value = String(source || "")

        if (value.length === 0) {
            return ""
        }
        if (usableIconSource(value)) {
            return value.indexOf("/") === 0 ? "file://" + value : value
        }

        return Quickshell.iconPath(value, "")
    }

    Layout.alignment: Qt.AlignVCenter
    Layout.preferredWidth: emphasized ? 132 : 46
    Layout.preferredHeight: 46

    radius: 8
    color: pointer.containsMouse
        ? SmokyPlumTheme.surfaceHover
        : (emphasized ? SmokyPlumTheme.highlightBackground : SmokyPlumTheme.surfaceActive)
    border.width: 1
    border.color: emphasized ? SmokyPlumTheme.highlightBorder : SmokyPlumTheme.borderSubtle

    Behavior on color {
        ColorAnimation {
            duration: Motion.fast
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: root.emphasized ? 8 : 0
            rightMargin: root.emphasized ? 8 : 0
        }

        spacing: 8

        Item {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28

            IconImage {
                id: dockIcon

                anchors.centerIn: parent

                visible: root.resolvedIconSource.length > 0 && status !== Image.Error
                source: root.resolvedIconSource
                asynchronous: true
                implicitSize: 22
                width: 22
                height: 22
            }

            Text {
                anchors.centerIn: parent

                visible: !dockIcon.visible
                text: root.marker
                color: root.emphasized ? SmokyPlumTheme.accentRose : SmokyPlumTheme.textSecondary
                font.pixelSize: 9
                font.weight: Font.DemiBold
                textFormat: Text.PlainText
            }
        }

        ColumnLayout {
            visible: root.emphasized
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            RevealText {
                text: root.label
                color: SmokyPlumTheme.textPrimary
                font.weight: Font.DemiBold
                maximumTextWidth: 82
            }

            RevealText {
                text: root.detail
                color: SmokyPlumTheme.textMuted
                font.pixelSize: 9
                maximumTextWidth: 82
            }
        }
    }

    Rectangle {
        visible: root.running
        anchors {
            bottom: parent.bottom
            bottomMargin: 3
            horizontalCenter: parent.horizontalCenter
        }

        width: 5
        height: 5
        radius: 3
        color: SmokyPlumTheme.accentRose
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
