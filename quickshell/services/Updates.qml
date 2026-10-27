pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Package updates for the tiny PKG readout. `checkupdates` refreshes its own
// temporary sync database, so the bar never blocks on a full system upgrade.
Singleton {
    id: root

    property int count: -1
    property bool checking: false

    function refresh() {
        if (probe.running)
            return;
        checking = true;
        probe.running = true;
    }

    Process {
        id: probe

        command: ["checkupdates"]
        running: false
        stdout: StdioCollector {
            id: output

            onStreamFinished: {
                const lines = (text || "").split("\n").filter(line => line.trim() !== "");
                root.count = lines.length;
                root.checking = false;
            }
        }
    }

    Timer {
        interval: 6 * 60 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
