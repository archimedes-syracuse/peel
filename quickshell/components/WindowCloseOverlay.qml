import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../theme"
import "../services"

PanelWindow {
    id: root

    property var modelData

    readonly property int buttonWidth: 46
    readonly property int buttonHeight: 34
    readonly property int borderWidth: 1
    readonly property int cornerRadius: 0
    readonly property int fadeDuration: 120

    readonly property color restGlyphColor: Theme.deskTextDim
    readonly property color hoverGlyphColor: Theme.deskHighlight
    readonly property color hoverFillColor: Theme.bgHover

    readonly property var ignoreAppIds: [
        "vscodium", "codium", "code-oss", "code",
        "firefox", "librewolf", "chrom", "chrome", "brave", "vivaldi",
        "opera", "edge", "thunderbird", "celluloid", "vlc"
    ]

    property var liveClients: []

    readonly property var client: {
        const list = liveClients.length > 0 ? liveClients : (Mango.allClients || []);
        for (let i = 0; i < list.length; i++) {
            const c = list[i];
            if (c && c.is_focused && c.is_visible && !c.is_minimized)
                return c;
        }
        return Mango.available ? Mango.focusedClient : null;
    }

    readonly property bool onThisOutput: client !== null
        && (client.monitor === "" || client.monitor === modelData.name)
    readonly property bool hasClient: client !== null
        && client.is_focused
        && client.is_visible
        && !client.is_minimized
        && !client.is_fullscreen
        && onThisOutput
        && !isIgnored(client.appid)
        && client.width > buttonWidth + borderWidth * 2
        && client.height > buttonHeight + borderWidth * 2
    readonly property real buttonX: hasClient
        ? client.x + client.width - borderWidth - buttonWidth
        : 0
    readonly property real buttonY: hasClient
        ? Math.max(Mango.barInset, client.y + borderWidth)
        : 0

    function isIgnored(appid) {
        const id = String(appid || "").toLowerCase();
        for (let i = 0; i < ignoreAppIds.length; i++) {
            if (id === ignoreAppIds[i] || id.indexOf(ignoreAppIds[i]) !== -1)
                return true;
        }
        return false;
    }

    function closeById(id) {
        if (id === undefined || id === null)
            return;
        Quickshell.execDetached(["mmsg", "dispatch", "killclient", "client," + id]);
    }

    screen: modelData
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusiveZone: 0
    focusable: false
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "mango-shell-window-close"

    mask: Region {
        item: closeButton
    }

    Process {
        id: watchProc

        command: ["mmsg", "watch", "all-clients"]
        running: Mango.available
        stdout: SplitParser {
            onRead: data => {
                const raw = String(data).trim();
                if (raw === "")
                    return;
                try {
                    const parsed = JSON.parse(raw);
                    if (parsed && Array.isArray(parsed.clients))
                        root.liveClients = parsed.clients;
                } catch (e) {
                }
            }
        }
        onExited: root.liveClients = []
    }

    Rectangle {
        id: closeButton

        width: root.hasClient ? root.buttonWidth : 0
        height: root.hasClient ? root.buttonHeight : 0
        x: root.buttonX
        y: root.buttonY
        color: closeHover.hovered ? root.hoverFillColor : "transparent"
        radius: root.cornerRadius
        border.width: 0

        Behavior on color { ColorAnimation { duration: root.fadeDuration } }

        Text {
            anchors.centerIn: parent
            text: "\u00D7"
            color: closeHover.hovered ? root.hoverGlyphColor : root.restGlyphColor
            font.family: Theme.font
            font.pixelSize: 16

            Behavior on color { ColorAnimation { duration: root.fadeDuration } }
        }

        HoverHandler {
            id: closeHover
            cursorShape: Qt.PointingHandCursor
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: root.closeById(root.client ? root.client.id : -1)
        }
    }
}
