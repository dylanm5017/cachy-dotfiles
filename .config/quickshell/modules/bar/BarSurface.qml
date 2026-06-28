import QtQuick
import Quickshell

PanelWindow {
    id: root

    required property var modelData

    screen: modelData
    implicitHeight: 46
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
    }

    exclusiveZone: height

    Bar {
        anchors.fill: parent
        panelWindow: root
    }
}
