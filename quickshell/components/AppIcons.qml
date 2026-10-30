import QtQuick
import QtQuick.Effects
import Quickshell
import "../theme"
import "../services"
import "../components"

Item {
    id: root

    readonly property int iconSize: 16
    readonly property int cellWidth: 24
    readonly property var windowClients: Mango.allClients

    property string monitorName: ""

    readonly property var apps: {
        const out = [];
        const seen = {};
        const clients = windowClients || [];
        for (let i = 0; i < clients.length; i++) {
            const client = clients[i];
            if (!client || !isOnActiveTag(client))
                continue;
            const appid = String(client.appid || "");
            const key = appid !== "" ? appid : "client-" + client.id;
            if (seen[key])
                continue;
            seen[key] = true;
            out.push({
                appid: appid,
                title: String(client.title || ""),
                id: client.id
            });
        }
        return out;
    }

    readonly property var activeTags: {
        const indices = [];
        const groups = Mango.allTags || [];
        for (let i = 0; i < groups.length; i++) {
            const group = groups[i];
            if (!group)
                continue;
            if (root.monitorName !== "" && group.monitor !== root.monitorName)
                continue;
            const tags = group.tags || [];
            for (let j = 0; j < tags.length; j++) {
                if (tags[j] && tags[j].is_active)
                    indices.push(tags[j].index);
            }
        }
        return indices;
    }

    function isOnActiveTag(client) {
        const tags = client.tags || [];
        const active = activeTags;
        if (active.length === 0)
            return true;
        for (let i = 0; i < tags.length; i++) {
            if (active.indexOf(tags[i]) !== -1)
                return true;
        }
        return false;
    }

    visible: apps.length > 0
    implicitWidth: visible ? apps.length * cellWidth + 8 : 0
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight

    function focusClient(id) {
        Mango.dispatch("focusid", "client," + id);
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.barPill
        border.width: 1
        border.color: Theme.barGlassBorder
    }

    Row {
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: root.apps

            Item {
                id: cell

                required property var modelData
                required property int index

                width: root.cellWidth
                height: root.iconSize
                readonly property bool hovered: hover.containsMouse

                Image {
                    id: icon

                    anchors.centerIn: parent
                    width: root.iconSize
                    height: root.iconSize
                    readonly property int revision: Icons.revision
                    source: {
                        if (revision < 0)
                            return "";
                        return Icons.resolve(cell.modelData.appid);
                    }
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    visible: false
                }

                ShaderEffectSource {
                    id: capture

                    sourceItem: icon
                    width: root.iconSize
                    height: root.iconSize
                    live: false
                    hideSource: true
                    visible: false
                }

                MultiEffect {
                    anchors.centerIn: parent
                    width: root.iconSize
                    height: root.iconSize
                    source: capture
                    visible: icon.source !== "" && icon.status === Image.Ready
                    colorization: 1.0
                    colorizationColor: Theme.deskText
                    opacity: cell.hovered ? 1.0 : 0.8
                }

                Text {
                    anchors.centerIn: parent
                    visible: icon.source === "" || icon.status === Image.Error
                    text: Icons.glyph(cell.modelData.appid)
                    color: cell.hovered ? Theme.deskText : Theme.deskTextDim
                    font.family: Theme.font
                    font.pixelSize: 14
                    layer.enabled: true
                    layer.effect: TextOutline {}
                }

                MouseArea {
                    id: hover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusClient(cell.modelData.id)
                }
            }
        }
    }
}
