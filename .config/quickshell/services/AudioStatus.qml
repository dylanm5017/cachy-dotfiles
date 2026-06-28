pragma Singleton

import QtQml
import Quickshell.Services.Pipewire

QtObject {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property bool ready: Pipewire.ready && audio !== null
    readonly property int volume: audio ? Math.round(audio.volume * 100) : 0
    readonly property bool muted: audio ? audio.muted : false
    property bool osdVisible: false
    property bool initialized: false
    property PwObjectTracker sinkTracker: PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    function setVolume(percent) {
        if (audio) {
            audio.volume = Math.max(0, Math.min(1.5, percent / 100))
        }
    }

    function toggleMuted() {
        if (audio) {
            audio.muted = !audio.muted
        }
    }

    function showOsd() {
        if (initialized && ready) {
            osdVisible = true
            osdTimer.restart()
        }
    }

    onVolumeChanged: showOsd()
    onMutedChanged: showOsd()

    Component.onCompleted: Qt.callLater(function() {
        root.initialized = true
    })

    property Timer osdTimer: Timer {
        interval: 1300
        onTriggered: root.osdVisible = false
    }
}
