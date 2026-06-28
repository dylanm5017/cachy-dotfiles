import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.." 1.0
import "../../services" 1.0

PanelWindow {
    id: root

    required property var modelData
    property bool isFocusedScreen: false

    screen: modelData
    visible: isFocusedScreen && NotificationState.count > 0 && !CommandState.visible && !QuietState.enabled
    implicitWidth: 384
    implicitHeight: toastColumn.implicitHeight
    color: "transparent"
    exclusiveZone: 0

    anchors {
        top: true
        right: true
    }

    margins {
        top: 54
        right: 12
    }

    ColumnLayout {
        id: toastColumn

        anchors.fill: parent
        spacing: 10

        Repeater {
            model: NotificationState.notifications

            delegate: NotificationToast {
                required property var modelData

                notification: modelData
            }
        }
    }
}
