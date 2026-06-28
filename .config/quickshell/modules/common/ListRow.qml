import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../.." 1.0

// Flat list row: real app icon (resolved from themed names) + text, hover-only
// background, no per-row border or nested marker box.
Rectangle {
    id: root

    property string marker: ""
    property string iconSource: ""
    property string label: ""
    property string detail: ""
    property string trailing: ""
    property bool interactive: true
    property color hoverColor: SmokyPlumTheme.surfaceHover
    property color markerColor: SmokyPlumTheme.accentRose
    property color labelColor: SmokyPlumTheme.textSecondary
    property color detailColor: SmokyPlumTheme.textMuted

    // Legacy / ignored after de-box.
    property color fillColor: "transparent"
    property color markerFillColor: "transparent"
    property color borderColor: "transparent"

    readonly property string resolvedIconSource: resolveIconSource(iconSource)

    signal clicked()

    function resolveIconSource(source) {
        const value = String(source || "")

        if (value.length === 0) {
            return ""
        }
        if (value.indexOf("/") === 0) {
            return "file://" + value
        }
        if (value.indexOf("file:") === 0
            || value.indexOf("image:") === 0
            || value.indexOf("qrc:") === 0) {
            return value
        }

        return Quickshell.iconPath(value, "")
    }

    Layout.fillWidth: true
    Layout.preferredHeight: implicitHeight

    implicitHeight: detail.length > 0 ? 40 : 34
    radius: 8
    color: interactive && pointer.containsMouse ? hoverColor : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Motion.fast
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 8
            rightMargin: 10
        }

        spacing: 10

        Item {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24

            IconImage {
                id: rowIcon

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
                visible: !rowIcon.visible
                text: root.marker
                color: root.markerColor
                font.pixelSize: 9
                font.weight: Font.DemiBold
                textFormat: Text.PlainText
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            RevealText {
                text: root.label
                color: root.labelColor
                font.weight: Font.Medium
                maximumTextWidth: 340
            }

            Text {
                visible: root.detail.length > 0
                Layout.fillWidth: true
                text: root.detail
                color: root.detailColor
                elide: Text.ElideRight
                font.pixelSize: 9
                textFormat: Text.PlainText
                wrapMode: Text.NoWrap
            }
        }

        Text {
            visible: root.trailing.length > 0
            text: root.trailing
            color: SmokyPlumTheme.textDisabled
            font.pixelSize: 9
            textFormat: Text.PlainText
        }
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: root.interactive
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
