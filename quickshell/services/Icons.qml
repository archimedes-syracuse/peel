import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton
Singleton {
    id: root

    readonly property var iconThemes: ["WhiteSur-dark", "WhiteSur", "breeze", "Adwaita", "hicolor"]
    readonly property var iconSizes: [32, 48, 24, 64, 16, 128, 256, 22]
    readonly property string iconRoot: "/usr/share/icons"

    readonly property string indexCommand:
        "for t in " + iconThemes.join(" ") + "; do for s in "
        + iconSizes.join(" ") + "; do for f in " + iconRoot + "/$t/apps/$s/*; do"
        + " [ -f \"$f\" ] && printf '%s\\t%s\\n' \"$(basename \"$f\" | sed 's/\\.[^.]*$//')\" \"$f\";"
        + " done; done; done;"
        + "for t in " + iconThemes.join(" ") + "; do for f in " + iconRoot + "/$t/apps/scalable/*; do"
        + " [ -f \"$f\" ] && printf '%s\\t%s\\n' \"$(basename \"$f\" | sed 's/\\.[^.]*$//')\" \"$f\";"
        + " done; done"

    property var index: ({})
    property bool indexed: false

    property int revision: 0

    property bool entriesReady: false
    Timer {
        interval: 300
        running: !root.entriesReady && root.indexed
        repeat: true
        onTriggered: {
            if (DesktopEntries.applications.values.length > 0) {
                root.entriesReady = true;
                root.revision++;
            }
        }
    }

    Component.onCompleted: buildIndex()

    function buildIndex() {
        if (lister.running)
            return;
        lister.running = true;
    }

    Process {
        id: lister

        running: false
        command: ["sh", "-c", root.indexCommand]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = (text || "").split("\n");
                const map = {};
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    if (line === "")
                        continue;
                    const tab = line.indexOf("\t");
                    if (tab < 0)
                        continue;
                    const name = line.substring(0, tab);
                    const path = line.substring(tab + 1);
                    if (map[name] === undefined)
                        map[name] = path;
                }
                root.index = map;
                root.indexed = true;
                root.revision++;
            }
        }
    }

    function desktopIconName(appid) {
        if (appid === "")
            return "";

        const entries = DesktopEntries.applications.values;
        for (let i = 0; i < entries.length; i++) {
            const entry = entries[i];
            if (!entry)
                continue;
            const id = String(entry.id || "").replace(/\.desktop$/, "");
            const startup = String(entry.startupClass || "");
            if (id === appid || id.toLowerCase() === appid.toLowerCase() || startup === appid)
                return entry.icon ? String(entry.icon) : "";
        }
        return "";
    }

    function lookup(name) {
        if (name === "")
            return "";

        const direct = Quickshell.iconPath(name, true);
        if (direct !== "")
            return direct;

        const hit = index[name];
        return hit !== undefined ? hit : "";
    }

    function resolve(appid) {
        const clean = String(appid || "");

        const themed = desktopIconName(clean);
        if (themed !== "") {
            const found = lookup(themed);
            if (found !== "")
                return found;
        }

        const direct = lookup(clean);
        if (direct !== "")
            return direct;

        const tail = clean.indexOf(".") !== -1 ? clean.substring(clean.lastIndexOf(".") + 1) : "";
        if (tail !== "") {
            const tailFound = lookup(tail);
            if (tailFound !== "")
                return tailFound;
        }

        return "";
    }

    function glyph(appid) {
        const id = String(appid || "").toLowerCase();
        if (id.indexOf("konsole") !== -1 || id.indexOf("terminal") !== -1
                || id.indexOf("alacritty") !== -1 || id.indexOf("kitty") !== -1
                || id.indexOf("foot") !== -1)
            return "\uF120";
        if (id.indexOf("firefox") !== -1 || id.indexOf("chrom") !== -1
                || id.indexOf("brave") !== -1 || id.indexOf("edge") !== -1
                || id.indexOf("browser") !== -1)
            return "\uF269";
        if (id.indexOf("code") !== -1 || id.indexOf("editor") !== -1
                || id.indexOf("vim") !== -1)
            return "\uF121";
        if (id.indexOf("nautilus") !== -1 || id.indexOf("thunar") !== -1
                || id.indexOf("files") !== -1)
            return "\uF07B";
        return "\uF2D0";
    }
}
