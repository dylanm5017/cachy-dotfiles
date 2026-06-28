import QtQuick
import Quickshell
import "../common" 1.0

PanelWindow {
    id: root

    required property var modelData
    property bool isFocusedScreen: false

    screen: modelData
    visible: isFocusedScreen
    implicitHeight: 86
    color: "transparent"
    exclusiveZone: 0
    aboveWindows: true

    anchors {
        bottom: true
        left: true
        right: true
    }

    SmartDock {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 12
        }
    }
}
