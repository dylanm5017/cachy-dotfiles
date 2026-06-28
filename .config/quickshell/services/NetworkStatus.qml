pragma Singleton

import QtQml
import Quickshell.Io

QtObject {
    id: root

    // "ethernet" | "wifi" | "none"
    property string kind: "none"
    property string label: "Offline"
    property int strength: 0
    property bool wifiEnabled: true
    readonly property bool online: kind !== "none"
    readonly property string leading: kind === "ethernet"
        ? "ETH"
        : (kind === "wifi" ? "WIFI" : "NET")
    readonly property string detail: kind === "wifi" && strength > 0
        ? strength + "%"
        : ""

    function refresh() {
        if (!statusProc.running) {
            statusProc.running = true
        }
        if (!wifiProc.running) {
            wifiProc.running = true
        }
        if (!radioProc.running) {
            radioProc.running = true
        }
    }

    function toggleWifi() {
        toggleProc.command = ["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"]
        toggleProc.running = true
    }

    function parseStatus(text) {
        const lines = String(text || "").trim().split("\n")
        let eth = null
        let wifi = null

        for (let i = 0; i < lines.length; i += 1) {
            const parts = lines[i].split(":")

            if (parts.length < 3) {
                continue
            }

            const type = parts[0]
            const state = parts[1]
            const conn = parts.slice(2).join(":")

            if (state !== "connected") {
                continue
            }

            if (type === "ethernet" && eth === null) {
                eth = conn
            } else if (type === "wifi" && wifi === null) {
                wifi = conn
            }
        }

        if (eth !== null) {
            kind = "ethernet"
            label = "Wired"
        } else if (wifi !== null) {
            kind = "wifi"
            label = wifi.length > 0 ? wifi : "Wi-Fi"
        } else {
            kind = "none"
            label = wifiEnabled ? "Offline" : "Wi-Fi off"
            strength = 0
        }
    }

    function parseWifi(text) {
        const lines = String(text || "").trim().split("\n")

        for (let i = 0; i < lines.length; i += 1) {
            const parts = lines[i].split(":")

            if (parts.length < 2) {
                continue
            }

            if (parts[0] === "*") {
                strength = parseInt(parts[1]) || 0
                return
            }
        }
    }

    function parseRadio(text) {
        wifiEnabled = String(text || "").trim() === "enabled"
    }

    property Process statusProc: Process {
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device", "status"]
        stdout: StdioCollector {
            id: statusCollector
            onStreamFinished: root.parseStatus(statusCollector.text)
        }
    }

    property Process wifiProc: Process {
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL", "device", "wifi"]
        stdout: StdioCollector {
            id: wifiCollector
            onStreamFinished: root.parseWifi(wifiCollector.text)
        }
    }

    property Process radioProc: Process {
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        stdout: StdioCollector {
            id: radioCollector
            onStreamFinished: root.parseRadio(radioCollector.text)
        }
    }

    property Process toggleProc: Process {
        command: ["nmcli", "radio", "wifi"]
        onRunningChanged: {
            if (!running) {
                root.refresh()
            }
        }
    }

    property Timer pollTimer: Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
