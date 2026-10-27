import Quickshell
import Quickshell.Wayland
import QtQuick
import "../theme"

// A plain dmenu-style application launcher: one black panel, a white prompt
// and cursor at the left, and the matching applications listed beside it. No
// title bar, no footer, no window chrome. Type to filter, arrows to move,
// Enter to launch, Escape to dismiss.
PanelWindow {
    id: root

    visible: false
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusiveZone: 0
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "niri-shell-launcher"

    property string query: ""
    property int sel: 0
    readonly property int maxResults: 10
    readonly property var results: filterApps(query)

    // Keep the launcher plain for now: black panel, white text, and the
    // arrow is the only selection marker.
    readonly property color launchText: "#ffffff"
    readonly property color launchBg: "#000000"

    function open() {
        input.text = "";
        query = "";
        sel = 0;
        visible = true;
        input.forceActiveFocus();
        focusTimer.running = true;
    }

    function close() {
        visible = false;
        input.text = "";
    }

    function lock() {
        Quickshell.execDetached(["swaylock", "-f"]);
        close();
    }

    function filterApps(q) {
        const all = DesktopEntries.applications.values;
        const needle = (q || "").trim().toLowerCase();
        const out = [];
        const seen = {};
        for (let i = 0; i < all.length; i++) {
            const entry = all[i];
            if (!entry || entry.noDisplay)
                continue;
            const name = entry.name || "";
            if (name === "" || seen[name])
                continue;
            const hay = (name + " " + (entry.genericName || "") + " " + (entry.comment || "")).toLowerCase();
            if (needle !== "" && hay.indexOf(needle) === -1)
                continue;
            seen[name] = true;
            out.push(entry);
        }
        out.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        return out.slice(0, maxResults);
    }

    onResultsChanged: {
        if (results.length === 0)
            sel = 0;
        else
            sel = Math.max(0, Math.min(results.length - 1, sel));
    }

    function launch(i) {
        if (i < 0 || i >= results.length)
            return;
        results[i].execute();
        close();
    }

    function move(delta) {
        if (results.length === 0)
            return;
        sel = (sel + delta + results.length) % results.length;
    }

    Timer {
        id: focusTimer
        interval: 30
        onTriggered: input.forceActiveFocus()
    }

    // Clicking outside the panel dismisses it without a scrim.
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card

        width: 820
        height: content.implicitHeight + 24
        implicitHeight: height
        anchors.centerIn: parent
        color: root.launchBg
        radius: 0

        MouseArea { anchors.fill: parent }

        // Wheel/touchpad scrolling moves the selected row, including when the
        // launcher first opens with the full list showing.
        WheelHandler {
            onWheel: (event) => {
                const delta = event.angleDelta.y !== 0
                    ? event.angleDelta.y
                    : event.pixelDelta.y;
                if (delta !== 0)
                    root.move(delta > 0 ? -1 : 1);
                event.accepted = true;
            }
        }

        Row {
            id: content

            x: 12
            y: 12
            width: parent.width - 24
            spacing: 8

            Row {
                id: promptRow

                spacing: 2

                Text {
                    id: promptText

                    height: 20
                    text: "Launch:"
                    color: root.launchText
                    font.family: Theme.font
                    font.pixelSize: 14
                    verticalAlignment: Text.AlignVCenter
                }

                TextInput {
                    id: input

                    width: Math.min(220, Math.max(2, contentWidth + 2))
                    height: 20
                    font.family: Theme.font
                    font.pixelSize: 14
                    color: root.launchText
                    selectionColor: root.launchText
                    selectedTextColor: root.launchBg
                    focus: true
                    clip: true
                    verticalAlignment: Text.AlignVCenter

                    cursorDelegate: Rectangle {
                        width: 2
                        height: 14
                        color: root.launchText
                        visible: input.activeFocus
                    }

                    onTextChanged: root.query = text
                    Keys.onEscapePressed: root.close()
                    Keys.onReturnPressed: root.launch(root.sel)
                    Keys.onEnterPressed: root.launch(root.sel)
                    Keys.onDownPressed: root.move(1)
                    Keys.onUpPressed: root.move(-1)
                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_L && (event.modifiers & Qt.ControlModifier)) {
                            root.lock();
                            event.accepted = true;
                        }
                    }
                }
            }

            Column {
                id: resultList

                width: content.width - promptRow.width - content.spacing
                spacing: 0

                Repeater {
                    model: root.results

                    Item {
                        id: row

                        readonly property bool picked: index === root.sel

                        width: resultList.width
                        height: 20

                        Text {
                            anchors {
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                            }
                            text: row.picked ? ">" : " "
                            color: root.launchText
                            font.family: Theme.font
                            font.pixelSize: 14
                        }

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 16
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            text: modelData.name
                            color: root.launchText
                            font.family: Theme.font
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }

                        HoverHandler {
                            id: hover
                            cursorShape: Qt.PointingHandCursor

                            onHoveredChanged: {
                                if (hovered)
                                    root.sel = index;
                            }
                        }

                        TapHandler {
                            onTapped: root.launch(index)
                        }
                    }
                }

                Text {
                    visible: root.results.length === 0
                    width: resultList.width
                    height: 20
                    text: "No matches"
                    color: root.launchText
                    font.family: Theme.font
                    font.pixelSize: 14
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
