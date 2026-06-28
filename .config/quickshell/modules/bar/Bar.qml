import QtQuick
import QtQuick.Layouts
import "../.." 1.0
import "../common" 1.0
import "../island" 1.0

Item {
    id: root

    property var panelWindow

    // Left zone — flat, no container box.
    RowLayout {
        anchors {
            left: parent.left
            leftMargin: 14
            verticalCenter: parent.verticalCenter
        }

        spacing: 12

        WorkspaceList {}

        FocusedWindowChip {}
    }

    // Center island — the one intentionally framed element.
    Rectangle {
        id: centerIsland

        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }

        width: centerContent.implicitWidth
        height: centerContent.implicitHeight
        radius: 9
        color: SmokyPlumTheme.surfaceSunken

        RowLayout {
            id: centerContent

            anchors.centerIn: parent
            spacing: 0

            DynamicIsland {}
        }
    }

    // Right zone — flat glyphs, no container box.
    RowLayout {
        anchors {
            right: parent.right
            rightMargin: 14
            verticalCenter: parent.verticalCenter
        }

        spacing: 8

        SystemTrayCluster {
            panelWindow: root.panelWindow
        }

        StatusCluster {}

        VolumeText {}
    }
}
