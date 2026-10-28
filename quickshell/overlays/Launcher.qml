import Quickshell
import Quickshell.Wayland
import QtQuick
import "../theme"

// A plain dmenu-style application launcher: one black panel, a white prompt
// and cursor at the top, and the matching applications listed below. The list
// shows ten rows and scrolls through every match. No title bar, no footer, no
// window chrome. Type to filter, arrows to move, Enter to launch, Escape to
// dismiss.
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
    property int entriesRevision: 0
    property bool entriesReady: false
    readonly property int visibleRows: 10
    readonly property int rowHeight: 20
    readonly property var results: {
        // Read the revision so a late-loading desktop-entry model refreshes
        // the filtered list instead of leaving it stuck on "No matches".
        entriesRevision;
        return filterApps(query);
    }

    // Match the other monochrome panels: off-white text on the solid desk
    // panel with a hairline border, not pure white on pure black.
    readonly property color launchText: Theme.deskText
    readonly property color launchBg: Theme.deskPanelSolid
    readonly property color launchBorder: Theme.deskBorder

    function open() {
        input.text = "";
        query = "";
        sel = 0;
        entriesReady = false;
        entriesRevision++;
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
        return out;
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

    function wheelMove(event) {
        const delta = event.angleDelta.y !== 0
            ? event.angleDelta.y
            : event.pixelDelta.y;
        if (delta !== 0)
            root.move(delta > 0 ? -1 : 1);
        event.accepted = true;
    }

    Timer {
        id: focusTimer
        interval: 30
        onTriggered: input.forceActiveFocus()
    }

    // Desktop entries can load after the shell starts or reloads. Refresh once
    // they are available so typed queries do not get stuck on "No matches".
    Timer {
        interval: 300
        repeat: true
        running: root.visible && !root.entriesReady
        onTriggered: {
            if (DesktopEntries.applications.values.length > 0) {
                root.entriesReady = true;
                root.entriesRevision++;
            }
        }
    }

    // Clicking outside the panel dismisses it without a scrim. The wheel
    // handler here also keeps scrolling alive after the result card shrinks.
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()

        WheelHandler {
            onWheel: (event) => root.wheelMove(event)
        }
    }

    Rectangle {
        id: card

        width: 820
        height: content.implicitHeight + 24
        implicitHeight: height
        anchors.centerIn: parent
        color: root.launchBg
        radius: 0
        border.width: 1
        border.color: root.launchBorder

        MouseArea { anchors.fill: parent }

        // Wheel/touchpad scrolling moves the selected row, including when the
        // launcher first opens with the full list showing.
        WheelHandler {
            onWheel: (event) => root.wheelMove(event)
        }

        Column {
            id: content

            x: 12
            y: 12
            width: parent.width - 24
            spacing: 4

            Row {
                id: promptRow

                width: content.width
                spacing: 2

                Text {
                    id: promptText

                    height: 20
                    text: "Launch:"
                    color: Theme.deskTextDim
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

            Item {
                id: resultsBox

                width: content.width
                height: Math.min(Math.max(root.results.length, 1), root.visibleRows) * root.rowHeight

                ListView {
                    id: resultList

                    anchors.fill: parent
                    visible: root.results.length > 0
                    clip: true
                    interactive: false
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.results
                    currentIndex: root.sel

                    onCurrentIndexChanged: {
                        if (currentIndex >= 0 && count > 0)
                            positionViewAtIndex(currentIndex, ListView.Contain);
                    }

                    onCountChanged: {
                        if (root.sel >= 0 && root.sel < count)
                            positionViewAtIndex(root.sel, ListView.Contain);
                    }

                    delegate: Item {
                        id: row

                        readonly property bool picked: index === root.sel

                        width: resultList.width
                        height: root.rowHeight

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

                    WheelHandler {
                        onWheel: (event) => root.wheelMove(event)
                    }
                }

                Text {
                    visible: root.results.length === 0
                    width: resultsBox.width
                    height: root.rowHeight
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
