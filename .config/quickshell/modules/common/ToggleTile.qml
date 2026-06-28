import QtQuick
import QtQuick.Layouts
import "../.." 1.0

Rectangle {
    id: root

    property string marker: ""
    property string title: ""
    property string state: ""
    property bool active: false

    signal clicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 54

    radius: 10
    color: active
        ? SmokyPlumTheme.highlightBackground
        : (pointer.containsMouse ? SmokyPlumTheme.surfaceHover : SmokyPlumTheme.surfaceSunken)

    Behavior on color {
        ColorAnimation {
            duration: Motion.fast
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 12
        }

        spacing: 10

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 8
            Layout.preferredHeight: 8
            radius: 4
            color: root.active ? SmokyPlumTheme.accentRose : SmokyPlumTheme.textDisabled

            Behavior on color {
                ColorAnimation {
                    duration: Motion.fast
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.title
                color: SmokyPlumTheme.textPrimary
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }

            Text {
                visible: root.state.length > 0
                Layout.fillWidth: true
                text: root.state
                color: root.active ? SmokyPlumTheme.accentRose : SmokyPlumTheme.textMuted
                font.pixelSize: 9
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }
        }
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
