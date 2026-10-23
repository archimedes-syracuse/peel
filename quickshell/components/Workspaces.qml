import QtQuick
import "../theme"
import "../services"

// Numeric workspace/tag strip for the vertical rail. Active is the only
// accent; occupied workspaces are quieter, empty ones recede almost
// completely. Mango reports every tag (1..5), so client_count distinguishes
// occupied tags from empty ones.
Column {
    id: root

    property string monitorName: ""

    spacing: 1

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

            width: 28
            height: 23

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: item.selected
                    ? Theme.accentSoft
                    : hover.hovered ? Theme.bgHover : "transparent"
                border.width: item.selected ? 1 : 0
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45)

                Behavior on color { ColorAnimation { duration: Theme.duration } }
            }

            Text {
                anchors.centerIn: parent
                text: String(index + 1)
                color: item.selected ? Theme.accent : hover.hovered ? Theme.fg : item.used ? Theme.fg : Theme.fgDim
                opacity: item.selected ? 1 : hover.hovered ? 1 : item.used ? 0.8 : 0.35
                font.family: Theme.font
                font.pixelSize: Theme.size
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
