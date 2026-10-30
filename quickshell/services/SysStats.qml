pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpu: 0
    property real mem: 0
    property real memUsed: 0
    property real memTotal: 0

    property real prevTotal: 0
    property real prevIdle: 0

    function clamp(v) {
        return Math.max(0, Math.min(100, v));
    }

    function parse(raw) {
        const lines = (raw || "").split("\n");
        if (lines.length < 2)
            return;

        const fields = lines[0].trim().split(/\s+/).slice(1).map(Number);
        if (fields.length >= 4) {
            let total = 0;
            for (let i = 0; i < fields.length; i++)
                total += fields[i];
            const idle = fields[3] + (fields[4] || 0);

            if (root.prevTotal > 0 && total > root.prevTotal) {
                const dt = total - root.prevTotal;
                const di = idle - root.prevIdle;
                if (dt > 0)
                    root.cpu = root.clamp(100 * (1 - di / dt));
            }
            root.prevTotal = total;
            root.prevIdle = idle;
        }

        let totalKb = 0;
        let availKb = 0;
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (line.startsWith("MemTotal:"))
                totalKb = parseInt(line.replace(/\D+/g, ""), 10);
            else if (line.startsWith("MemAvailable:"))
                availKb = parseInt(line.replace(/\D+/g, ""), 10);
        }

        if (totalKb > 0) {
            root.memTotal = totalKb / 1048576;
            root.memUsed = (totalKb - availKb) / 1048576;
            root.mem = root.clamp(100 * root.memUsed / root.memTotal);
        }
    }

    Process {
        id: sampler
        command: ["sh", "-c", "head -1 /proc/stat; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"]
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
        onTriggered: sampler.running = true
    }
}
