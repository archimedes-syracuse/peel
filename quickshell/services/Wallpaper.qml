pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string picturesDir: (Quickshell.env("HOME") || "") + "/Pictures"
    readonly property string stateFile: Quickshell.statePath("wallpaper.json")

    readonly property string mode: "fill"

    property var entries: []
    property string currentPath: ""

    property bool _stateLoaded: false
    property bool _runningChecked: false
    property bool _scanDone: false
    property string _runningPath: ""

    function fileUrl(path) {
        if (!path)
            return "";
        return "file://" + path.split("/").map(encodeURIComponent).join("/");
    }

    function basename(path) {
        if (!path)
            return "";
        const index = path.lastIndexOf("/");
        return index >= 0 ? path.substring(index + 1) : path;
    }

    function relPath(path) {
        if (!path)
            return "";
        const prefix = root.picturesDir + "/";
        return path.indexOf(prefix) === 0 ? path.substring(prefix.length) : path;
    }

    function scan() {
        root._scanDone = false;
        scanProc.running = false;
        scanProc.running = true;
    }

    function apply(path) {
        if (!path)
            return;

        root.currentPath = path;
        root.save();

        // One swaybg per output: replace the old instance instead of stacking.
        Quickshell.execDetached([
            "sh", "-c",
            "pkill -x swaybg; sleep 0.12; exec swaybg -i \"$1\" -m \"$2\"",
            "swaybg", path, root.mode
        ]);
    }

    function random() {
        if (root.entries.length === 0)
            return;
        const index = Math.floor(Math.random() * root.entries.length);
        root.apply(root.entries[index]);
    }

    function save() {
        store.setText(JSON.stringify({ path: root.currentPath }, null, 2));
    }

    function reconcile() {
        if (!root._stateLoaded || !root._runningChecked || !root._scanDone)
            return;

        if (root.currentPath === "" && root._runningPath !== "") {
            root.currentPath = root._runningPath;
            root.save();
        }

        if (root.currentPath === "") {
            if (root.entries.length > 0) {
                root.currentPath = root.entries[0];
                root.apply(root.currentPath);
            }
            return;
        }

        if (root.entries.indexOf(root.currentPath) === -1) {
            if (root.entries.indexOf(root._runningPath) !== -1) {
                root.currentPath = root._runningPath;
                root.save();
                return;
            }
            if (root.entries.length > 0) {
                root.currentPath = root.entries[0];
                root.apply(root.currentPath);
            }
            return;
        }

        if (root._runningPath !== root.currentPath)
            root.apply(root.currentPath);
    }

    Component.onCompleted: {
        root.scan();
        runningProc.running = true;
    }

    IpcHandler {
        target: "wallpaper"

        function get(): string {
            return root.currentPath;
        }

        function set(path: string): void {
            root.apply(path);
        }

        function list(): string {
            return root.entries.join("\n");
        }

        function refresh(): void {
            root.scan();
        }

        function random(): void {
            root.random();
        }
    }

    FileView {
        id: store

        path: root.stateFile
        blockLoading: true
        watchChanges: false
        printErrors: false

        onLoaded: {
            try {
                const data = JSON.parse(store.text());
                if (data && typeof data.path === "string")
                    root.currentPath = data.path;
            } catch (e) {
            }
            root._stateLoaded = true;
            root.reconcile();
        }

        onLoadFailed: {
            root._stateLoaded = true;
            root.reconcile();
        }
    }

    Process {
        id: scanProc

        command: [
            "sh", "-c",
            "find \"$1\" -maxdepth 2 -type f "
                + "\\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' "
                + "-o -iname '*.webp' -o -iname '*.bmp' \\) "
                + "! -path '*/Screenshots/*' -print | sort",
            "wallpaper-scan", root.picturesDir
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                const found = [];
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (line !== "")
                        found.push(line);
                }
                root.entries = found;
                root._scanDone = true;
                root.reconcile();
            }
        }
    }

    Process {
        id: runningProc

        command: [
            "sh", "-c",
            "for p in $(pgrep -x swaybg); do tr '\\000' '\\n' < /proc/$p/cmdline; done"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                let path = "";
                for (let i = 0; i < lines.length - 1; i++) {
                    if (lines[i] === "-i") {
                        path = lines[i + 1];
                        break;
                    }
                }
                root._runningPath = path;
                root._runningChecked = true;
                root.reconcile();
            }
        }
    }
}
