import QtQuick
import Quickshell
import Quickshell.Io
import "modules"
import "services" 1.0

Scope {
    IpcHandler {
        target: "shell"

        function toggleLauncher(): void {
            CommandState.toggle()
        }

        function toggleControlCenter(): void {
            ControlCenterState.toggle()
        }

        function toggleNotifications(): void {
            NotificationCenterState.toggle()
        }

        function toggleCalendar(): void {
            CalendarState.toggle()
        }

        function toggleCheatsheet(): void {
            CheatsheetState.toggle()
        }

        function toggleMedia(): void {
            MediaPopupState.toggle()
        }

        function toggleDnd(): void {
            QuietState.toggle()
        }

        function powerMenu(): void {
            PowerMenuState.toggle()
        }
    }

    Variants {
        model: Quickshell.screens

        ScreenShell {
            modelData: modelData
        }
    }
}
