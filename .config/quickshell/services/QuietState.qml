pragma Singleton

import QtQml

QtObject {
    id: root

    // Do Not Disturb. When enabled, transient notification toasts are
    // suppressed but notifications are still recorded for the notification
    // center.
    property bool enabled: false

    function toggle() {
        enabled = !enabled
    }

    function setEnabled(value) {
        enabled = value
    }
}
