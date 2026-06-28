import QtQuick
import QtQuick.Layouts
import "../.." 1.0
import "../common" 1.0
import "../../services" 1.0

RowLayout {
    id: root

    Layout.alignment: Qt.AlignVCenter
    spacing: 4

    // Do Not Disturb — only while active, so suppressed notifications aren't a surprise.
    StatusPill {
        visible: QuietState.enabled
        leadingText: "DND"
        label: "Quiet"
        maximumWidth: 96
        interactive: true
        leadingColor: SmokyPlumTheme.diagnosticWarning
        labelColor: SmokyPlumTheme.textMuted
        onClicked: ControlCenterState.toggle()
    }

    // Bluetooth — only when a device is actually connected (named).
    StatusPill {
        visible: BluetoothStatus.connected
        leadingText: "BT"
        label: BluetoothStatus.connectedDevice
        maximumWidth: 150
        interactive: true
        leadingColor: SmokyPlumTheme.accentRose
        labelColor: SmokyPlumTheme.textSecondary
        onClicked: ControlCenterState.toggle()
    }
}
