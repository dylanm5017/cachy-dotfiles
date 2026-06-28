import QtQml
import Quickshell
import Quickshell.Hyprland
import "bar"
import "dock"
import "overlays"

Scope {
    id: root

    required property var modelData

    readonly property var hyprMonitor: Hyprland.monitorFor(modelData)
    readonly property bool isFocusedScreen: hyprMonitor ? hyprMonitor.focused : false

    BarSurface {
        modelData: root.modelData
    }

    // Bottom smart dock — disabled for now; re-enable to bring it back.
    // SmartDockSurface {
    //     modelData: root.modelData
    //     isFocusedScreen: root.isFocusedScreen
    // }

    AudioOsd {
        modelData: root.modelData
        isFocusedScreen: root.isFocusedScreen
    }

    CommandDrawer {
        modelData: root.modelData
        isFocusedScreen: root.isFocusedScreen
    }

    ControlCenter {
        modelData: root.modelData
        isFocusedScreen: root.isFocusedScreen
    }

    NotificationCenter {
        modelData: root.modelData
        isFocusedScreen: root.isFocusedScreen
    }

    CalendarPopup {
        modelData: root.modelData
        isFocusedScreen: root.isFocusedScreen
    }

    PowerMenu {
        modelData: root.modelData
        isFocusedScreen: root.isFocusedScreen
    }

    Cheatsheet {
        modelData: root.modelData
        isFocusedScreen: root.isFocusedScreen
    }

    MediaPopup {
        modelData: root.modelData
        isFocusedScreen: root.isFocusedScreen
    }

    NotificationToastStack {
        modelData: root.modelData
        isFocusedScreen: root.isFocusedScreen
    }
}
