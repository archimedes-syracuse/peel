pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int pct: -1
    property string status: ""

    readonly property bool charging: status === "Charging" || status === "Full"
    readonly property bool low: pct >= 0 && pct <= 15 && status === "Discharging"
    readonly property bool present: pct >= 0

    function parse(raw) {
        const line = (raw || "").trim().split("\n")[0];
        if (line === "")
            return;
        const parts = line.split("|");
        const value = parseInt(parts[0], 10);
        root.pct = isNaN(value) ? -1 : value;
        root.status = (parts[1] || "").trim();
    }

    Process {
        id: probe
        command: ["sh", "-c", "for d in /sys/class/power_supply/BAT*; do echo \"$(cat $d/capacity 2>/dev/null)|$(cat $d/status 2>/dev/null)\"; done"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: probe.running = true
    }
}
