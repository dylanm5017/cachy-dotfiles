pragma Singleton

import QtQml
import Quickshell.Io

QtObject {
    id: root

    property bool visible: false
    property var binds: []

    function open() {
        visible = true
        reload()
    }

    function close() {
        visible = false
    }

    function toggle() {
        visible = !visible

        if (visible) {
            reload()
        }
    }

    function reload() {
        if (!proc.running) {
            proc.running = true
        }
    }

    function modString(mask) {
        const parts = []

        if (mask & 64) {
            parts.push("Super")
        }
        if (mask & 4) {
            parts.push("Ctrl")
        }
        if (mask & 8) {
            parts.push("Alt")
        }
        if (mask & 1) {
            parts.push("Shift")
        }

        return parts.join(" + ")
    }

    // Map the project's own IPC dispatches to friendly names.
    readonly property var ipcLabels: ({
        "toggleLauncher": "Launcher",
        "toggleControlCenter": "Control center",
        "toggleNotifications": "Notifications",
        "toggleCalendar": "Calendar",
        "toggleCheatsheet": "Keybind cheatsheet",
        "toggleMedia": "Media player",
        "toggleDnd": "Do not disturb",
        "powerMenu": "Power menu"
    })

    // Friendlier names for the common Hyprland dispatchers.
    readonly property var dispatcherLabels: ({
        "killactive": "Close window",
        "togglefloating": "Toggle floating",
        "fullscreen": "Fullscreen",
        "fakefullscreen": "Fake fullscreen",
        "togglesplit": "Toggle split",
        "pseudo": "Pseudo-tile",
        "pin": "Pin window",
        "exit": "Exit Hyprland",
        "workspace": "Workspace",
        "movetoworkspace": "Move to workspace",
        "movetoworkspacesilent": "Move to workspace (silent)",
        "movefocus": "Focus",
        "movewindow": "Move window",
        "resizeactive": "Resize window",
        "splitratio": "Adjust split ratio",
        "togglespecialworkspace": "Special workspace"
    })

    function prettyAction(dispatcher, arg) {
        // exec rules: surface friendly names for our own IPC, otherwise the command.
        if (dispatcher === "exec") {
            const ipcMatch = arg.match(/ipc\s+call\s+shell\s+(\w+)/)

            if (ipcMatch && ipcLabels[ipcMatch[1]]) {
                return ipcLabels[ipcMatch[1]]
            }

            // Strip a leading "uwsm app --" / "uwsm-app --" wrapper if present.
            const cleaned = arg.replace(/^uwsm(-| )app\s+--\s*/, "").trim()

            return cleaned.length > 0 ? cleaned : "Run command"
        }

        const base = dispatcherLabels[dispatcher]
            || (dispatcher.charAt(0).toUpperCase() + dispatcher.slice(1))

        // Keep the meaningful argument (workspace number, direction) but drop noise.
        if (arg.length > 0 && arg !== "active") {
            return base + " " + arg
        }

        return base
    }

    function parse(text) {
        try {
            const data = JSON.parse(String(text || "[]"))
            const list = []

            for (let i = 0; i < data.length; i += 1) {
                const bind = data[i]
                const dispatcher = String(bind.dispatcher || "")
                const arg = String(bind.arg || "")
                const key = String(bind.key || (bind.keycode ? "code:" + bind.keycode : ""))

                if (key.length === 0) {
                    continue
                }

                list.push({
                    mods: modString(bind.modmask),
                    key: key,
                    action: prettyAction(dispatcher, arg)
                })
            }

            binds = list
        } catch (error) {
            binds = []
        }
    }

    property Process proc: Process {
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: root.parse(collector.text)
        }
    }
}
