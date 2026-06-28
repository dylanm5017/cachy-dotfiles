import QtQuick
import QtQuick.Layouts
import "../.." 1.0

// Flat status item: small accent glyph/label + text, hover-only background, no
// borders or nested boxes. Legacy color properties are accepted but ignored so
// existing callers keep working after the de-box rework.
Item {
    id: root

    property string leadingText: ""
    property string label: ""
    property string detail: ""
    property int maximumWidth: 240
    property bool interactive: false
    property color leadingColor: SmokyPlumTheme.accentRose
    property color labelColor: SmokyPlumTheme.textSecondary
    property color detailColor: SmokyPlumTheme.textMuted

    // Legacy / ignored.
    property color fillColor: "transparent"
    property color borderColor: "transparent"
    property color slotColor: "transparent"

    signal clicked()

    Layout.alignment: Qt.AlignVCenter
    Layout.maximumWidth: maximumWidth
    Layout.preferredHeight: implicitHeight

    implicitWidth: Math.min(maximumWidth, content.implicitWidth + 12)
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: 7
        color: root.interactive && pointer.containsMouse
            ? SmokyPlumTheme.surfaceHover
            : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: Motion.fast
            }
        }
    }

    RowLayout {
        id: content

        anchors {
            fill: parent
            leftMargin: 7
            rightMargin: 7
        }

        spacing: 5

        Text {
            visible: root.leadingText.length > 0
            text: root.leadingText
            color: root.leadingColor
            font.pixelSize: 8
            font.weight: Font.DemiBold
            textFormat: Text.PlainText
        }

        RevealText {
            fill: false
            text: root.label
            color: root.labelColor
            font.weight: Font.Medium
            maximumTextWidth: root.maximumWidth - 44
        }

        Text {
            visible: root.detail.length > 0
            text: root.detail
            color: root.detailColor
            font.pixelSize: 10
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
