import Quickshell
import Quickshell.Wayland
import QtQuick
import "../theme"

// Fullscreen app launcher. Keyboard focus is taken only while open.
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
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "niri-shell-launcher"

    property string query: ""
    readonly property var results: filterApps(query)
    property int sel: 0

    function open() {
        input.text = "";
        query = "";
        sel = 0;
        visible = true;
        focusTimer.running = true;
    }

    function close() {
        visible = false;
        input.text = "";
    }

    function toggle() {
        if (visible)
            close();
        else
            open();
    }

    function filterApps(q) {
        const all = DesktopEntries.applications.values;
        const needle = (q || "").trim().toLowerCase();
        const out = [];
        for (let i = 0; i < all.length; i++) {
            const entry = all[i];
            if (!entry)
                continue;
            const hay = (entry.name + " " + (entry.genericName || "") + " " + (entry.keywords || []).join(" ")).toLowerCase();
            if (needle === "" || hay.indexOf(needle) !== -1)
                out.push(entry);
        }
        out.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        return out.slice(0, 8);
    }

    onResultsChanged: sel = 0

    function launch(i) {
        if (i < 0 || i >= results.length)
            return;
        results[i].execute();
        close();
    }

    onVisibleChanged: {
        if (visible) {
            card.scale = 0.96;
            card.opacity = 0;
            intro.restart();
        }
    }

    Timer {
        id: focusTimer
        interval: 60
        onTriggered: input.forceActiveFocus()
    }

    Rectangle {
        anchors.fill: parent
        color: "#99070a10"

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Rectangle {
        id: card

        width: Math.min(640, root.width - 120)
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height * 0.16
        implicitHeight: column.implicitHeight + 20
        color: Theme.bgPanel
        radius: 12
        border.width: 1
        border.color: Theme.border

        MouseArea { anchors.fill: parent }

        ParallelAnimation {
            id: intro
            NumberAnimation { target: card; property: "scale"; to: 1; duration: 180; easing.type: Easing.OutCubic }
            NumberAnimation { target: card; property: "opacity"; to: 1; duration: 140 }
        }

        Column {
            id: column
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            Rectangle {
                width: parent.width
                height: 46
                radius: 8
                color: Theme.bgHover

                Text {
                    id: searchIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.gSearch
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: 18
                }

                TextInput {
                    id: input
                    anchors.left: searchIcon.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.font
                    font.pixelSize: Theme.sizeTitle
                    color: Theme.fg
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.bg
                    clip: true

                    onTextChanged: root.query = text
                    Keys.onEscapePressed: root.close()
                    Keys.onReturnPressed: root.launch(root.sel)
                    Keys.onDownPressed: root.sel = Math.min(root.results.length - 1, root.sel + 1)
                    Keys.onUpPressed: root.sel = Math.max(0, root.sel - 1)
                }
            }

            Text {
                visible: root.results.length === 0
                text: "no matches"
                color: Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.size
                leftPadding: 12
                topPadding: 6
            }

            Repeater {
                model: root.results

                Rectangle {
                    width: column.width
                    height: 34
                    radius: 8
                    color: index === root.sel ? Theme.accent : "transparent"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        width: parent.width - 24
                        text: modelData.name
                        color: index === root.sel ? Theme.bg : Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.size
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.sel = index
                        onClicked: root.launch(index)
                    }
                }
            }
        }
    }
}
