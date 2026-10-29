import QtQuick
import "../theme"
import "../services"
import "../components"

// Bare workspace numbers for the top bar. No boxes, no icons, no badges:
// the active tag is white, occupied tags are grey, and empty tags recede into
// the bar. The same tag data drives Mango, labwc and Niri.
Row {
    id: root

    property string monitorName: ""

    spacing: 10

    readonly property var all: Compositor.tagsFor(monitorName)

    function goTo(idx) {
        Compositor.focusTag(idx, monitorName);
    }

    Repeater {
        model: 5

        Item {
            id: item

            readonly property var workspace: {
                for (let i = 0; i < root.all.length; i++) {
                    const tag = root.all[i];
                    const number = tag.idx !== undefined ? tag.idx : tag.index;
                    if (number === index + 1)
                        return tag;
                }
                return null;
            }

            readonly property bool used: {
                if (!workspace)
                    return false;
                if (typeof workspace.client_count === "number")
                    return workspace.client_count > 0;
                return true;
            }

            readonly property bool selected: workspace ? workspace.is_active === true : false

            width: 13
            height: 24

            Text {
                anchors.centerIn: parent
                text: String(index + 1)
                color: item.selected
                    ? Theme.accent
                    : hover.hovered ? Theme.deskText : Theme.deskTextDim
                opacity: item.selected || hover.hovered ? 1 : item.used ? 0.8 : 0.35
                font.family: Theme.font
                font.pixelSize: 14
                layer.enabled: true
                layer.effect: TextOutline {}
                font.bold: item.selected

                Behavior on color { ColorAnimation { duration: Theme.duration } }
                Behavior on opacity { NumberAnimation { duration: Theme.duration } }
            }

            HoverHandler {
                id: hover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: root.goTo(index + 1)
            }
        }
    }

    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y > 0)
                Compositor.workspaceUp();
            else
                Compositor.workspaceDown();
        }
    }
}
