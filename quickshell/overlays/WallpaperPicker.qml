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
    readonly property int visibleSide: 4          // neighbours drawn per side
    readonly property real baseAngle: 78          // first neighbour rotation (deg)
    readonly property real angleStep: 2           // extra rotation per further item
    readonly property real maxAngle: 82           // clamp
    readonly property real shrink: 0.20           // scale falloff per step
    readonly property int gap: 8                  // px between items

    readonly property int cardH: Math.round(height * 0.56)
    readonly property int cardW: Math.round(cardH * 16 / 9)

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
    function scaleFor(ad) {
        return 1 / (1 + ad * shrink);
    }

    function angleFor(d) {
        const ad = Math.abs(d);
        if (ad === 0)
            return 0;
        return (d < 0 ? 1 : -1) * Math.min(maxAngle, baseAngle + angleStep * (ad - 1));
    }

    // Half of an item's on-screen width once rotated (orthographic projection).
    function halfWidthAt(ad) {
        if (ad === 0)
            return cardW / 2;
        const a = Math.min(maxAngle, baseAngle + angleStep * (ad - 1));
        return cardW / 2 * scaleFor(ad) * Math.abs(Math.cos(a * Math.PI / 180));
    }

    // Distance from screen centre to the centre of an item |d| steps away.
    // Items are packed edge-to-edge with a gap, so the widths accumulate.
    function centerOffsetAt(ad) {
        let x = 0;
        for (let k = 1; k <= ad; k++)
            x += halfWidthAt(k - 1) + gap + halfWidthAt(k);
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

            property real rot: root.angleFor(d)

            width: root.cardW
            height: root.cardH
            x: root.width / 2 + (d < 0 ? -1 : 1) * root.centerOffsetAt(ad) - width / 2
            y: root.height / 2 - height / 2
            z: 1000 - ad
            visible: onScreen || opacity > 0.01
            opacity: onScreen ? Math.max(0.3, 1 - 0.18 * ad) : 0
            scale: root.scaleFor(ad)

            transform: Rotation {
                origin.x: cell.width / 2
                origin.y: cell.height / 2
                axis {
                    x: 0
                    y: 1
                    z: 0
                }
                angle: cell.rot
            }

            Behavior on x {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on rot {
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
                border.color: Theme.border
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

    // ── footer ──────────────────────────────────────────────────────────
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        text: Wallpaper.entries.length > 0
            ? Wallpaper.basename(Wallpaper.entries[root.selectedIndex])
                + "   ·   " + (root.selectedIndex + 1) + " / " + Wallpaper.entries.length
            : "No images in ~/Pictures"
        color: Theme.fgDim
        font.family: Theme.font
        font.pixelSize: Theme.size
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        text: "← →  browse    ·    click  apply    ·    esc  close"
        color: Theme.border
        font.family: Theme.font
        font.pixelSize: Theme.sizeSmall
    }
}
