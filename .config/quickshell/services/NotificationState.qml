pragma Singleton

import QtQml
import Quickshell.Services.Notifications

QtObject {
    id: root

    readonly property var notifications: server.trackedNotifications.values
    readonly property int count: notifications.length

    readonly property int maxHistory: 50
    property var history: []

    function dismiss(notification) {
        if (notification) {
            notification.dismiss()
        }
    }

    function record(notification) {
        if (!notification) {
            return
        }

        const entry = {
            appName: String(notification.appName || ""),
            summary: String(notification.summary || ""),
            body: String(notification.body || ""),
            image: String(notification.image || ""),
            appIcon: String(notification.appIcon || ""),
            critical: notification.urgency === NotificationUrgency.Critical,
            time: new Date()
        }

        const next = [entry]

        for (let i = 0; i < history.length && next.length < maxHistory; i += 1) {
            next.push(history[i])
        }

        history = next
    }

    function clearHistory() {
        history = []
    }

    property NotificationServer server: NotificationServer {
        keepOnReload: true
        persistenceSupported: false
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: true
        actionsSupported: true
        actionIconsSupported: false
        imageSupported: true
        inlineReplySupported: false

        onNotification: function(notification) {
            notification.tracked = true
            root.record(notification)
        }
    }
}
