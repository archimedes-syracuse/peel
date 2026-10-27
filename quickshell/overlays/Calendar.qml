import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../components"

// Month view opened by clicking the center clock. Keyboard-free by design:
// arrows change month, "today" returns, Escape or the backdrop closes.
PanelWindow {
    id: root

    property int monthOffset: 0

    readonly property date today: clock.date
    readonly property date shownDate: new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)
    readonly property int firstDay: (shownDate.getDay() + 6) % 7
    readonly property int cellWidth: 34

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
    WlrLayershell.namespace: "niri-shell-calendar"

    function open() {
        monthOffset = 0;
        visible = true;
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

    onVisibleChanged: {
        if (visible) {
            card.scale = 0.98;
            card.opacity = 0;
            intro.restart();
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.close()
    }

    Rectangle {
        anchors.fill: parent
        color: "#33070a10"

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    GlassPanel {
        id: card

        width: 260
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: Theme.gap
        }
        implicitHeight: content.implicitHeight + 20
        radius: Theme.radius
        borderWidth: 1

        MouseArea { anchors.fill: parent }

        ParallelAnimation {
            id: intro
            NumberAnimation { target: card; property: "scale"; to: 1; duration: 160; easing.type: Easing.OutCubic }
            NumberAnimation { target: card; property: "opacity"; to: 1; duration: 120 }
        }

        Column {
            id: content
            anchors.fill: parent
            anchors.margins: 10
            spacing: 5

            Item {
                width: parent.width
                height: 22

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(root.shownDate, "MMMM yyyy").toLowerCase()
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.size
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: Theme.gChevronLeft
                        color: hoverLeft.hovered ? Theme.accent : Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: Theme.iconSize

                        HoverHandler { id: hoverLeft; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: root.monthOffset-- }
                    }

                    Text {
                        text: Theme.gChevronRight
                        color: hoverRight.hovered ? Theme.accent : Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: Theme.iconSize

                        HoverHandler { id: hoverRight; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: root.monthOffset++ }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.border
            }

            Grid {
                width: parent.width
                columns: 7
                rowSpacing: 2

                Repeater {
                    model: ["mo", "tu", "we", "th", "fr", "sa", "su"]

                    Text {
                        width: root.cellWidth
                        height: 16
                        text: modelData
                        color: Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: Theme.sizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Grid {
                width: parent.width
                columns: 7
                rowSpacing: 2

                Repeater {
                    model: 42

                    Item {
                        id: day

                        readonly property date dayDate: new Date(root.shownDate.getFullYear(), root.shownDate.getMonth(), index - root.firstDay + 1)
                        readonly property bool inMonth: dayDate.getMonth() === root.shownDate.getMonth()
                        readonly property bool isToday: inMonth
                            && dayDate.getFullYear() === root.today.getFullYear()
                            && dayDate.getMonth() === root.today.getMonth()
                            && dayDate.getDate() === root.today.getDate()

                        width: root.cellWidth
                        height: 22

                        Rectangle {
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            radius: Theme.radius
                            color: day.isToday ? Theme.accentSoft : "transparent"
                            visible: day.inMonth
                        }

                        Text {
                            anchors.centerIn: parent
                            text: day.inMonth ? day.dayDate.getDate() : ""
                            color: day.isToday ? Theme.accent : Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.sizeSmall
                            font.bold: day.isToday
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.border
            }

            Item {
                width: parent.width
                height: 18

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "today"
                    color: hoverToday.hovered ? Theme.accent : Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.sizeSmall

                    HoverHandler { id: hoverToday; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.monthOffset = 0 }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "close"
                    color: hoverClose.hovered ? Theme.accent : Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.sizeSmall

                    HoverHandler { id: hoverClose; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.close() }
                }
            }
        }
    }
}
