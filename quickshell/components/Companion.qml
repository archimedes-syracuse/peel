import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

// A small pixel companion that lives above the wallpaper and windows. The
// layer surface is masked to the sprite only, so the rest of the screen stays
// usable while the character can still sit over a window edge.
PanelWindow {
    id: root

    property var modelData

    screen: modelData
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusiveZone: 0
    focusable: false
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "niri-shell-companion"

    mask: Region {
        item: spriteItem
    }

    Item {
        id: spriteItem

        x: Widgets.companionX
        y: Widgets.companionY
        width: 128
        height: 160
        property real idleOffset: 0

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            width: 62
            height: 5
            radius: 3
            color: "#66000000"
        }

        Image {
            anchors.fill: parent
            y: spriteItem.idleOffset
            source: "../assets/companion.png"
            fillMode: Image.PreserveAspectFit
            smooth: false
        }

        SequentialAnimation {
            running: true
            loops: Animation.Infinite
            NumberAnimation {
                target: spriteItem
                property: "idleOffset"
                to: -2
                duration: 1400
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: spriteItem
                property: "idleOffset"
                to: 0
                duration: 1400
                easing.type: Easing.InOutSine
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.OpenHandCursor
            drag.target: spriteItem
            drag.axis: Drag.XAndYAxis
            drag.minimumX: 8
            drag.maximumX: root.width - spriteItem.width - 8
            drag.minimumY: 8
            drag.maximumY: root.height - spriteItem.height - Theme.taskbarHeight - 8

            onReleased: Widgets.setCompanionPosition(spriteItem.x, spriteItem.y)
        }
    }
}
