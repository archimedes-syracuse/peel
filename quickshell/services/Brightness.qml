pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int pct: -1
    readonly property bool available: pct >= 0

    function setPct(value) {
        const next = Math.max(1, Math.min(100, Math.round(value)));
        root.pct = next;
        Quickshell.execDetached(["brightnessctl", "set", next + "%"]);
    }

    function parse(raw) {
        const line = (raw || "").trim().split("\n")[0];
        if (line === "")
            return;
        const fields = line.split(",");
        if (fields.length < 4)
            return;
        const value = parseInt(fields[3], 10);
        if (!isNaN(value))
            root.pct = value;
    }

    Process {
        id: probe
        command: ["brightnessctl", "-m"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!probe.running)
                probe.running = true;
        }
    }
}
