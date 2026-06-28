pragma Singleton

import QtQml
import Quickshell

QtObject {
    id: root

    property bool visible: false

    readonly property var actions: [
        { key: "lock", symbol: "LK", title: "Lock", detail: "session", danger: false },
        { key: "logout", symbol: "OUT", title: "Log out", detail: "exit Hyprland", danger: true },
        { key: "suspend", symbol: "ZZ", title: "Suspend", detail: "sleep", danger: false },
        { key: "reboot", symbol: "RB", title: "Restart", detail: "reboot", danger: true },
        { key: "shutdown", symbol: "PW", title: "Shut down", detail: "power off", danger: true }
    ]

    function open() {
        visible = true
    }

    function close() {
        visible = false
    }

    function toggle() {
        visible = !visible
    }

    function run(key) {
        switch (key) {
        case "lock":
            Quickshell.execDetached(["loginctl", "lock-session"])
            break
        case "logout":
            Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
            break
        case "suspend":
            Quickshell.execDetached(["systemctl", "suspend"])
            break
        case "reboot":
            Quickshell.execDetached(["systemctl", "reboot"])
            break
        case "shutdown":
            Quickshell.execDetached(["systemctl", "poweroff"])
            break
        }

        close()
    }
}
