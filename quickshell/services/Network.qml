pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// NetworkManager status via nmcli. Enough for the bar indicator; the
// network picker popup comes later.
Singleton {
    id: root

    property string kind: ""
    property string conn: ""
    property bool wifiEnabled: true

    readonly property bool online: kind !== ""

    function splitT(line) {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const ch = line[i];
            if (ch === "\\" && i + 1 < line.length) {
                const next = line[i + 1];
                if (next === ":" || next === "\\") {
                    cur += next;
                    i++;
                } else {
                    cur += ch;
                }
            } else if (ch === ":") {
                out.push(cur);
                cur = "";
            } else {
                cur += ch;
            }
        }
        out.push(cur);
        return out;
    }

    function parse(raw) {
        let foundKind = "";
        let foundConn = "";
        const lines = (raw || "").trim().split("\n");
        for (let i = 0; i < lines.length; i++) {
            if (lines[i] === "")
                continue;
            const p = root.splitT(lines[i]);
            if (p.length < 2)
                continue;
            const type = p[0];
            const state = p[1];
            const name = p.slice(2).join(":");
            if (state !== "connected")
                continue;
            if (type === "ethernet") {
                foundKind = "ethernet";
                foundConn = name;
                break;
            }
            if (type === "wifi" && foundKind === "") {
                foundKind = "wifi";
                foundConn = name;
            }
        }
        root.kind = foundKind;
        root.conn = foundConn;
    }

    Process {
        id: probe
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device", "status"]
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
