import Quickshell
import Quickshell.Wayland
import QtQuick
import "../theme"
import "../components"

// Centered app launcher. Keyboard focus is taken only while open.
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
        return out.slice(0, 6);
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
            card.scale = 0.98;
            card.opacity = 0;
            intro.restart();
        }
    }

    Timer {
        id: focusTimer
        interval: 50
        onTriggered: input.forceActiveFocus()
    }

    Rectangle {
        anchors.fill: parent
        color: "#66070a10"

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    GlassPanel {
        id: card

        width: Math.min(600, root.width - 120)
        anchors.centerIn: parent
        implicitHeight: column.implicitHeight + 24
        radius: 6
        borderWidth: 2

        MouseArea { anchors.fill: parent }

        ParallelAnimation {
            id: intro
            NumberAnimation { target: card; property: "scale"; to: 1; duration: 160; easing.type: Easing.OutCubic }
            NumberAnimation { target: card; property: "opacity"; to: 1; duration: 120 }
        }

        Column {
            id: column
            anchors.fill: parent
            anchors.margins: 10
            spacing: 5

            Rectangle {
                width: parent.width
                height: 42
                radius: Theme.radius
                color: Theme.surface

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 13
                    anchors.verticalCenter: parent.verticalCenter
                    text: "›"
                    color: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: Theme.sizeBig
                }

                TextInput {
                    id: input
                    anchors.left: parent.left
                    anchors.leftMargin: 30
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.font
                    font.pixelSize: Theme.sizeBig
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

                Text {
                    anchors.left: input.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text === ""
                    text: "Search…"
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.sizeBig
                }
            }

            Text {
                visible: root.results.length === 0
                text: "no matches"
                color: Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.size
                leftPadding: 10
                topPadding: 5
            }

            Repeater {
                model: root.results

                Rectangle {
                    width: column.width
                    height: 32
                    radius: Theme.radius
                    color: index === root.sel ? Theme.accentSoft : "transparent"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: parent.height - 8
                        radius: 1
                        color: Theme.accent
                        visible: index === root.sel
                    }

                    Behavior on color { ColorAnimation { duration: Theme.duration } }

                    Row {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 10
                            rightMargin: 10
                        }
                        spacing: 8

                        Image {
                            id: appIcon
                            width: 18
                            height: 18
                            anchors.verticalCenter: parent.verticalCenter
                            source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                            sourceSize.width: 18
                            sourceSize.height: 18
                            smooth: true
                            fillMode: Image.PreserveAspectFit
                            visible: source !== ""
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - (appIcon.visible ? appIcon.width + parent.spacing : 0)
                            text: modelData.name
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.size
                            elide: Text.ElideRight
                        }
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
