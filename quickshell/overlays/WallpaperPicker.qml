import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

// Wallpaper picker: a cover-flow carousel over ~/Pictures. The selected
// wallpaper sits centred at full size with no frame, no badge and no tint --
// it is just the image. Its neighbours recede to the sides as narrow,
// rotated slices. The current choice is also shown dimmed and full-bleed
// behind, so the whole screen previews it. Arrows (or the wheel) scroll, a
// click applies, Escape closes. The choice is persisted by Wallpaper.
PanelWindow {
    id: root

    // ── look ────────────────────────────────────────────────────────────
    readonly property int visibleSide: 3              // slices drawn per side
    readonly property real sideHeight: 0.92           // slice height vs card
    readonly property real sideWidth: 0.20            // first slice width vs card
    readonly property real sideShrink: 0.78           // width falloff per step
    readonly property int gap: 10                     // px between items
    // Neighbours are sheared very slightly so they fan out toward the bottom
    // instead of sitting as perfectly straight bars. Small on purpose.
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

    // ── geometry helpers ────────────────────────────────────────────────
    function sliceHeight() {
        return Math.round(cardH * sideHeight);
    }

    function sliceWidth(ad) {
        return Math.round(cardW * sideWidth * Math.pow(sideShrink, ad - 1));
    }

    // Shear for every tile, the selected card included: the whole row leans
    // the same way, bottom to the left, as in the mockup.
    function shearFor(d) {
        return -sideSlant;
    }

    // Distance from screen centre to the inner edge of the |ad|-th slice,
    // so slices pack outward edge-to-edge with a small gap.
    function sliceEdgeOffset(ad) {
        let x = cardW / 2 + gap;
        for (let k = 1; k < ad; k++)
            x += sliceWidth(k) + gap;
        return x;
    }

    // ── lifecycle ───────────────────────────────────────────────────────
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

    // Wrapping step through the images.
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

    // ── backdrop: the selected wallpaper, dimmed full-bleed ─────────────
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

    // ── carousel ────────────────────────────────────────────────────────
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
            // Shear about the top edge: neighbours lean very slightly away
            // from the centre at the bottom, so the row fans out a touch.
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

            // The selected tile is the raw image: no background fill, no
            // border, no highlight of any kind. Only the side slices keep the
            // 1px hairline that separates them from the dimmed backdrop.
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

    // ── keyboard ────────────────────────────────────────────────────────
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
