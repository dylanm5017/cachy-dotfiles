pragma Singleton

import QtQml
import Quickshell.Services.Mpris

QtObject {
    id: root

    readonly property var players: Mpris.players.values
    readonly property var player: selectPlayer()
    readonly property bool hasPlayer: player !== null
    readonly property bool isPlaying: hasPlayer && player.isPlaying
    readonly property string title: hasPlayer && player.trackTitle.length > 0 ? player.trackTitle : (hasPlayer ? player.identity : "")
    readonly property string artist: hasPlayer ? player.trackArtist : ""
    readonly property string artUrl: hasPlayer ? String(player.trackArtUrl || "") : ""
    readonly property real length: hasPlayer && player.lengthSupported ? player.length : 0
    readonly property bool canSeek: hasPlayer && player.canSeek
    readonly property bool canGoNext: hasPlayer && player.canGoNext
    readonly property bool canGoPrevious: hasPlayer && player.canGoPrevious
    property real position: 0

    function seekFraction(fraction) {
        if (player && canSeek && length > 0) {
            const target = Math.max(0, Math.min(1, fraction)) * length
            player.position = target
            position = target
        }
    }

    function refreshPosition() {
        position = (player && player.positionSupported) ? player.position : 0
    }

    function selectPlayer() {
        for (let i = 0; i < players.length; i += 1) {
            if (players[i].isPlaying) {
                return players[i]
            }
        }

        return players.length > 0 ? players[0] : null
    }

    function toggle() {
        if (!player) {
            return
        }

        if (player.canTogglePlaying) {
            player.togglePlaying()
        } else if (player.isPlaying && player.canPause) {
            player.pause()
        } else if (player.canPlay) {
            player.play()
        }
    }

    function next() {
        if (player && player.canGoNext) {
            player.next()
        }
    }

    function previous() {
        if (player && player.canGoPrevious) {
            player.previous()
        }
    }

    onPlayerChanged: refreshPosition()

    property Timer positionTimer: Timer {
        interval: 1000
        running: root.hasPlayer
        repeat: true
        onTriggered: root.refreshPosition()
    }
}
