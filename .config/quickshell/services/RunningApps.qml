pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // Original-case window classes of currently mapped Hyprland clients.
    property var classes: []

    function lower(value) {
        return String(value || "").toLowerCase()
    }

    function matchedClass(candidates) {
        for (let i = 0; i < classes.length; i += 1) {
            const running = lower(classes[i])

            for (let j = 0; j < candidates.length; j += 1) {
                const candidate = lower(candidates[j])

                if (candidate.length < 3) {
                    continue
                }

                if (running === candidate
                    || running.startsWith(candidate)
                    || candidate.startsWith(running)) {
                    return classes[i]
                }
            }
        }

        return ""
    }

    function isRunning(candidates) {
        return matchedClass(candidates).length > 0
    }

    function focusOrLaunch(entry, candidates) {
        const match = matchedClass(candidates)

        if (match.length > 0) {
            Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "class:^(" + match + ")$"])
        } else if (entry) {
            entry.execute()
        }
    }

    function refresh() {
        if (!proc.running) {
            proc.running = true
        }
    }

    function parse(text) {
        try {
            const data = JSON.parse(String(text || "[]"))
            const seen = []

            for (let i = 0; i < data.length; i += 1) {
                const cls = String(data[i].class || "")

                if (cls.length > 0 && seen.indexOf(cls) === -1) {
                    seen.push(cls)
                }
            }

            classes = seen
        } catch (error) {
            classes = []
        }
    }

    property Process proc: Process {
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: root.parse(collector.text)
        }
    }

    property Timer pollTimer: Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
