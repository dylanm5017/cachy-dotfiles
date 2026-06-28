pragma Singleton

import QtQml
import Quickshell.Io

QtObject {
    id: root

    property bool available: true
    property bool powered: false
    property string connectedDevice: ""
    readonly property bool connected: connectedDevice.length > 0
    readonly property string label: !available
        ? "No adapter"
        : (!powered
            ? "Off"
            : (connected ? connectedDevice : "On"))

    function refresh() {
        if (!showProc.running) {
            showProc.running = true
        }
        if (!devicesProc.running) {
            devicesProc.running = true
        }
    }

    function togglePowered() {
        toggleProc.command = ["bluetoothctl", "power", powered ? "off" : "on"]
        toggleProc.running = true
    }

    function parseShow(text) {
        const raw = String(text || "")

        if (raw.trim().length === 0) {
            available = false
            powered = false
            return
        }

        available = true
        powered = /Powered:\s*yes/i.test(raw)

        if (!powered) {
            connectedDevice = ""
        }
    }

    function parseDevices(text) {
        const lines = String(text || "").trim().split("\n")

        for (let i = 0; i < lines.length; i += 1) {
            // "Device AA:BB:CC:DD:EE:FF Some Headphones"
            const match = lines[i].match(/^Device\s+\S+\s+(.+)$/)

            if (match) {
                connectedDevice = match[1].trim()
                return
            }
        }

        connectedDevice = ""
    }

    property Process showProc: Process {
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            id: showCollector
            onStreamFinished: root.parseShow(showCollector.text)
        }
    }

    property Process devicesProc: Process {
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: StdioCollector {
            id: devicesCollector
            onStreamFinished: root.parseDevices(devicesCollector.text)
        }
    }

    property Process toggleProc: Process {
        command: ["bluetoothctl", "power", "on"]
        onRunningChanged: {
            if (!running) {
                root.refresh()
            }
        }
    }

    property Timer pollTimer: Timer {
        interval: 6000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
