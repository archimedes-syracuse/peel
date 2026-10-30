pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property bool powered: false
    property int connectedCount: 0

    function setPowered(on) {
        root.powered = on;
        Quickshell.execDetached(["bluetoothctl", "power", on ? "on" : "off"]);
    }

    function parse(raw) {
        const parts = (raw || "").split("===");
        const show = parts[0] || "";
        const connected = parts[1] || "";

        root.available = show.indexOf("Controller") !== -1;
        root.powered = /Powered:\s*yes/.test(show);

        let count = 0;
        const lines = connected.split("\n");
        for (let i = 0; i < lines.length; i++) {
            if (/^Device\s+[0-9A-F:]{17}/.test(lines[i]))
                count++;
        }
        root.connectedCount = count;
    }

    Process {
        id: probe
        command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -E '^(Controller|Powered)'; echo ===; bluetoothctl devices Connected 2>/dev/null"]
        running: false
        stderr: StdioCollector {}
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: probe.running = true
    }
}
