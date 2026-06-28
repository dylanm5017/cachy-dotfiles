pragma Singleton

import QtQml
import Quickshell

QtObject {
    id: root

    property bool visible: false
    property string query: ""

    readonly property var favoriteEntries: buildFavoriteEntries()
    readonly property var appEntries: buildAppEntries()
    readonly property var quickActions: buildQuickActions()
    readonly property bool searching: query.trim().length > 0
    readonly property var results: filterApps(query)

    function open() {
        visible = true
    }

    function close() {
        visible = false
        query = ""
    }

    function toggle() {
        visible = !visible

        if (!visible) {
            query = ""
        }
    }

    function scoreEntry(entry, needle) {
        const name = String(entry.name || "").toLowerCase()
        const generic = String(entry.genericName || "").toLowerCase()
        const comment = String(entry.comment || "").toLowerCase()

        if (name === needle) {
            return 1000
        }
        if (name.indexOf(needle) === 0) {
            return 800
        }

        const words = name.split(/[\s\-_.]+/)
        for (let i = 0; i < words.length; i += 1) {
            if (words[i].indexOf(needle) === 0) {
                return 700
            }
        }

        if (generic.indexOf(needle) === 0) {
            return 600
        }
        if (name.indexOf(needle) !== -1) {
            return 400
        }

        const gwords = generic.split(/[\s\-_.]+/)
        for (let i = 0; i < gwords.length; i += 1) {
            if (gwords[i].indexOf(needle) === 0) {
                return 350
            }
        }

        if (generic.indexOf(needle) !== -1) {
            return 200
        }
        // Comment matches rank lowest so "speedometer" never beats a real terminal for "ter".
        if (comment.indexOf(needle) !== -1) {
            return 50
        }

        return 0
    }

    function filterApps(text) {
        const needle = String(text || "").trim().toLowerCase()

        if (needle.length === 0) {
            return []
        }

        const all = DesktopEntries.applications.values
        const scored = []

        for (let i = 0; i < all.length; i += 1) {
            const entry = all[i]

            if (!entry || entry.noDisplay || !entry.name) {
                continue
            }

            const score = scoreEntry(entry, needle)

            if (score > 0) {
                scored.push({ entry: entry, score: score })
            }
        }

        scored.sort(function(a, b) {
            return b.score - a.score
                || String(a.entry.name).localeCompare(String(b.entry.name))
        })

        return scored.slice(0, 50).map(function(item) {
            return item.entry
        })
    }

    function launchFirstResult() {
        if (results.length > 0) {
            launch(results[0])
        }
    }

    function entryFor(candidates) {
        for (let i = 0; i < candidates.length; i += 1) {
            const entry = DesktopEntries.heuristicLookup(candidates[i])

            if (entry && !entry.noDisplay) {
                return entry
            }
        }

        return null
    }

    function launch(entry) {
        if (entry) {
            entry.execute()
            close()
        }
    }

    function launchByCandidates(candidates) {
        launch(entryFor(candidates))
    }

    function buildAppEntries() {
        const entries = DesktopEntries.applications.values
        const visibleEntries = []

        for (let i = 0; i < entries.length && visibleEntries.length < 12; i += 1) {
            const entry = entries[i]

            if (entry && !entry.noDisplay && entry.name.length > 0) {
                visibleEntries.push(entry)
            }
        }

        return visibleEntries
    }

    function buildFavoriteEntries() {
        const candidateGroups = [
            ["alacritty", "Alacritty", "kitty", "foot", "WezTerm"],
            ["firefox", "zen", "zen-browser", "chromium", "brave-browser"],
            ["code", "codium", "visual studio code"],
            ["org.kde.dolphin", "dolphin", "thunar", "nautilus"],
            ["discord", "vesktop"],
            ["pavucontrol", "qpwgraph"]
        ]
        const favorites = []

        for (let i = 0; i < candidateGroups.length; i += 1) {
            const entry = entryFor(candidateGroups[i])

            if (entry && favorites.indexOf(entry) === -1) {
                favorites.push(entry)
            }
        }

        for (let j = 0; j < appEntries.length && favorites.length < 8; j += 1) {
            if (favorites.indexOf(appEntries[j]) === -1) {
                favorites.push(appEntries[j])
            }
        }

        return favorites
    }

    function buildQuickActions() {
        const actions = [
            { key: "terminal", symbol: ">_", title: "Terminal", detail: "shell" },
            { key: "browser", symbol: "WEB", title: "Browser", detail: "open" },
            { key: "files", symbol: "DIR", title: "Files", detail: "browse" },
            { key: "reload", symbol: "QS", title: "Reload", detail: "shell" },
            { key: "lock", symbol: "LK", title: "Lock", detail: "session" }
        ]
        const available = []

        for (let i = 0; i < actions.length; i += 1) {
            if (actionAvailable(actions[i].key)) {
                available.push(actions[i])
            }
        }

        return available
    }

    function actionAvailable(key) {
        switch (key) {
        case "terminal":
            return entryFor(["alacritty", "Alacritty", "kitty", "foot", "WezTerm"]) !== null
        case "browser":
            return entryFor(["firefox", "zen", "zen-browser", "chromium", "brave-browser"]) !== null
        case "files":
            return entryFor(["org.kde.dolphin", "dolphin", "thunar", "nautilus"]) !== null
        case "reload":
        case "lock":
            return true
        default:
            return false
        }
    }

    function runAction(key) {
        switch (key) {
        case "terminal":
            launchByCandidates(["alacritty", "Alacritty", "kitty", "foot", "WezTerm"])
            break
        case "browser":
            launchByCandidates(["firefox", "zen", "zen-browser", "chromium", "brave-browser"])
            break
        case "files":
            launchByCandidates(["org.kde.dolphin", "dolphin", "thunar", "nautilus"])
            break
        case "reload":
            close()
            Quickshell.reload(false)
            break
        case "lock":
            close()
            Quickshell.execDetached(["loginctl", "lock-session"])
            break
        }
    }
}
