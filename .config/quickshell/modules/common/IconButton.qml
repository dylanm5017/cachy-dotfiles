import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../.." 1.0

Rectangle {
    id: root

    property string label: ""
    property string iconSource: ""
    property color foreground: pointer.containsMouse ? SmokyPlumTheme.textPrimary : SmokyPlumTheme.textMuted
    property color fillColor: pointer.containsMouse ? SmokyPlumTheme.surfaceHover : "transparent"
    property color borderColor: "transparent"

    signal clicked(var mouse)

    Layout.alignment: Qt.AlignVCenter

    implicitWidth: Math.max(24, buttonText.implicitWidth + 14)
    implicitHeight: 24
    radius: 7
    color: fillColor

    Behavior on color {
        ColorAnimation {
            duration: Motion.fast
        }
    }

    IconImage {
        id: buttonIcon

        anchors.centerIn: parent

        visible: root.iconSource.length > 0 && status !== Image.Error
        source: root.iconSource
        asynchronous: true
        implicitSize: 14
        width: 14
        height: 14
    }

    Text {
        id: buttonText

        anchors.centerIn: parent

        visible: !buttonIcon.visible
        text: root.label
        color: root.foreground
        font.pixelSize: root.label.length > 1 ? 9 : 11
        font.weight: Font.Medium
        textFormat: Text.PlainText
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) {
            root.clicked(mouse)
        }
    }
}
