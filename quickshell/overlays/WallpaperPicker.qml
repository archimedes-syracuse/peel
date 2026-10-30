import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

PanelWindow {
    id: root

    readonly property int visibleSide: 3
    readonly property real sideHeight: 0.92
    readonly property real sideWidth: 0.16
    readonly property real sideShrink: 0.78
    readonly property int gap: 10
    readonly property real sideSlant: 0.06

    readonly property int cardH: Math.round(height * 0.57)
    readonly property int cardW: Math.round(cardH * 1.62)

    property int selectedIndex: 0
    property bool _syncing: false

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
    WlrLayershell.namespace: "niri-shell-wallpaper"

    function sliceHeight() {
        return Math.round(cardH * sideHeight);
    }

    function sliceWidth(ad) {
        return Math.round(cardW * sideWidth * Math.pow(sideShrink, ad - 1));
    }

    function shearFor(d) {
        return -sideSlant;
    }

    function sliceEdgeOffset(ad) {
        let x = cardW / 2 + gap;
        for (let k = 1; k < ad; k++)
            x += sliceWidth(k) + gap;
        return x;
    }

    function open() {
        Wallpaper.scan();
        root._syncing = true;
        syncSelection();
        root._syncing = false;
        visible = true;
        focusTimer.running = true;
    }

    function close() {
        visible = false;
    }

    function toggle() {
        if (visible)
            close();
        else
            open();
    }

    function syncSelection() {
        const index = Wallpaper.entries.indexOf(Wallpaper.currentPath);
        root.selectedIndex = index >= 0 ? index : 0;
    }

    function move(delta) {
        const n = Wallpaper.entries.length;
        if (n === 0)
            return;
        root.selectedIndex = ((root.selectedIndex + delta) % n + n) % n;
    }

    onSelectedIndexChanged: {
        if (!root._syncing)
            applyTimer.restart();
    }

    Connections {
        target: Wallpaper

        function onEntriesChanged() {
            if (root.visible) {
                root._syncing = true;
                root.syncSelection();
                root._syncing = false;
            }
        }
    }

    Timer {
        id: applyTimer
        interval: 90
        onTriggered: {
            const n = Wallpaper.entries.length;
            if (n > 0)
                Wallpaper.apply(Wallpaper.entries[root.selectedIndex]);
        }
    }

    Timer {
        id: focusTimer
        interval: 30
        onTriggered: keyCatcher.forceActiveFocus()
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.close()
    }

    Image {
        anchors.fill: parent
        source: root.selectedIndex >= 0 && root.selectedIndex < Wallpaper.entries.length
            ? Wallpaper.fileUrl(Wallpaper.entries[root.selectedIndex])
            : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.55

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Repeater {
        model: Wallpaper.entries

        Item {
            id: cell

            required property string modelData
            required property int index

            readonly property int n: Wallpaper.entries.length
            readonly property int d: {
                let raw = index - root.selectedIndex;
                if (n > 2 * root.visibleSide) {
                    let dd = ((raw % n) + n) % n;
                    if (dd > n / 2)
                        dd -= n;
                    return dd;
                }
                return raw;
            }
            readonly property int ad: Math.abs(d)
            readonly property bool onScreen: ad <= root.visibleSide
            readonly property bool active: ad === 0

            width: active ? root.cardW : root.sliceWidth(ad)
            height: active ? root.cardH : root.sliceHeight()
            x: active
                ? root.width / 2 - width / 2
                : (d < 0
                    ? root.width / 2 - root.sliceEdgeOffset(ad) - width
                    : root.width / 2 + root.sliceEdgeOffset(ad))
            y: root.height / 2 - height / 2
            z: 1000 - ad
            visible: onScreen
            opacity: active ? 1 : Math.max(0.5, 1 - 0.14 * ad)
            transform: Matrix4x4 {
                matrix: Qt.matrix4x4(
                    1, root.shearFor(d), 0, -root.shearFor(d) * height / 2,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1)
            }

            Behavior on x {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 260
                }
            }

            Rectangle {
                anchors.fill: parent
                color: cell.active ? "transparent" : Theme.surface
                border.width: cell.active ? 0 : 1
                border.color: cell.active ? "transparent" : "#59ffffff"
                clip: true

                Image {
                    anchors.fill: parent
                    source: Wallpaper.fileUrl(cell.modelData)
                    sourceSize.width: root.cardW
                    sourceSize.height: root.cardH
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (cell.active)
                        root.close();
                    else
                        root.selectedIndex = cell.index;
                }
            }
        }
    }

    Item {
        id: keyCatcher

        anchors.fill: parent
        focus: true
        Keys.onLeftPressed: root.move(-1)
        Keys.onRightPressed: root.move(1)
        Keys.onUpPressed: root.move(-1)
        Keys.onDownPressed: root.move(1)
        Keys.onReturnPressed: root.close()
        Keys.onEnterPressed: root.close()
        Keys.onEscapePressed: root.close()

        WheelHandler {
            onWheel: event => root.move(event.angleDelta.y < 0 ? 1 : -1)
        }
    }

}
