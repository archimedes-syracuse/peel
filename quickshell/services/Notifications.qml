pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false
    property alias tracked: server.trackedNotifications
    readonly property int count: tracked ? tracked.values.length : 0

    function clearAll() {
        if (!tracked)
            return;
        const notes = tracked.values;
        for (let i = notes.length - 1; i >= 0; i--)
            notes[i].dismiss();
    }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        imageSupported: true
        actionsSupported: true

        onNotification: (n) => {
            if (root.dnd) {
                n.dismiss();
                return;
            }
            n.tracked = true;
        }
    }
}
