pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int pct: -1
    readonly property bool available: pct >= 0

    function parse(raw) {
        const lines = (raw || "").trim().split("\n");
        if (lines.length < 2)
            return;
        const fields = lines[lines.length - 1].trim().split(/\s+/);
        if (fields.length < 5)
            return;
        const value = parseInt(fields[4], 10);
        if (!isNaN(value))
            root.pct = value;
    }

    Process {
        id: probe
        command: ["df", "-P", "/"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!probe.running)
                probe.running = true;
        }
    }
}
