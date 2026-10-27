import QtQuick
import "../theme"
import "../services"

// Horizontal five-workspace strip for the bottom taskbar. This intentionally
// keeps the same data path as the old vertical rail.
Row {
    id: root

    property string monitorName: ""

    spacing: 2

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

            width: 25
            height: 24

            Rectangle {
                anchors.fill: parent
                radius: 2
                color: item.selected
                    ? Theme.accentSoft
                    : hover.hovered ? Theme.bgHover : "transparent"
                border.width: item.selected ? 1 : 0
                border.color: Theme.accent

                Behavior on color { ColorAnimation { duration: Theme.duration } }
            }

            Text {
                anchors.centerIn: parent
                text: String(index + 1)
                color: item.selected ? Theme.accent : hover.hovered ? Theme.deskText : item.used ? Theme.deskTextDim : Theme.deskTextDim
                opacity: item.selected || hover.hovered ? 1 : item.used ? 0.8 : 0.45
                font.family: Theme.fontRetro
                font.pixelSize: 9
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
