pragma Singleton

import QtQml
import Quickshell

QtObject {
    id: root

    readonly property int maxHistoryItems: 6
    readonly property int maxStoredCharacters: 1000
    property var history: []
    readonly property string currentText: Quickshell.clipboardText
    readonly property string preview: previewText(currentText)
    readonly property bool hasText: preview.length > 0

    function previewText(text) {
        return String(text || "").replace(/\s+/g, " ").trim()
    }

    function remember(text) {
        const cleanText = String(text || "").trim()
        const previewValue = previewText(cleanText)

        if (previewValue.length === 0) {
            return
        }

        const storedText = cleanText.slice(0, maxStoredCharacters)
        const nextHistory = [storedText]

        for (let i = 0; i < history.length && nextHistory.length < maxHistoryItems; i += 1) {
            if (history[i] !== storedText) {
                nextHistory.push(history[i])
            }
        }

        history = nextHistory
    }

    function copy(text) {
        Quickshell.clipboardText = text
        remember(text)
    }

    onCurrentTextChanged: remember(currentText)

    Component.onCompleted: remember(currentText)
}
