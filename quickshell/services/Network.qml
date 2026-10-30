pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string kind: ""
    property string conn: ""
    property string iface: ""
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
        let foundIface = "";
        const lines = (raw || "").trim().split("\n");
        for (let i = 0; i < lines.length; i++) {
            if (lines[i] === "")
                continue;
            const p = root.splitT(lines[i]);
            if (p.length < 3)
                continue;
            const type = p[0];
            const state = p[1];
            const name = p[2];
            const device = p.length > 3 ? p[3] : "";
            if (state !== "connected")
                continue;
            if (type === "ethernet") {
                foundKind = "ethernet";
                foundConn = name;
                foundIface = device;
                break;
            }
            if (type === "wifi" && foundKind === "") {
                foundKind = "wifi";
                foundConn = name;
                foundIface = device;
            }
        }
        root.kind = foundKind;
        root.conn = foundConn;
        root.iface = foundIface;
    }

    Process {
        id: probe
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION,DEVICE", "device", "status"]
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
