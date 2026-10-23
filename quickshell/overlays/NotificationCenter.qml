import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../components"
import "../services"

// Notification history panel, opened from the bell in the bar.
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
    WlrLayershell.namespace: "niri-shell-notifications-center"

    function open() {
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

        width: 320
        anchors {
            top: parent.top
            right: parent.right
            topMargin: Theme.gap
            rightMargin: Theme.barWidth + Theme.gap
        }
        implicitHeight: column.implicitHeight + 20
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
            spacing: 7

            Item {
                width: parent.width
                height: 20

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "notifications"
                    color: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: Theme.size
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifications.count === 0 ? "empty" : Notifications.count + " new"
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.sizeSmall
                }
            }

            Item {
                width: parent.width
                height: 20

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifications.dnd ? "do not disturb · on" : "do not disturb · off"
                    color: Notifications.dnd ? Theme.accent2 : Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.sizeSmall
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.dnd = !Notifications.dnd
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.border
            }

            Text {
                visible: Notifications.count === 0
                text: "nothing here yet"
                color: Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.size
                topPadding: 4
                bottomPadding: 4
            }

            Repeater {
                model: Notifications.tracked

                Rectangle {
                    width: column.width
                    implicitHeight: noteColumn.implicitHeight + 14
                    radius: Theme.radius
                    color: Theme.surface

                    Column {
                        id: noteColumn
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 3

                        Text {
                            width: parent.width
                            text: modelData.appName || "notification"
                            color: Theme.accent
                            font.family: Theme.font
                            font.pixelSize: Theme.sizeSmall
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            text: modelData.summary
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.size
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        Text {
                            width: parent.width
                            visible: modelData.body !== ""
                            text: modelData.body
                            color: Theme.fgDim
                            font.family: Theme.font
                            font.pixelSize: 11
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            maximumLineCount: 4
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.dismiss()
                    }
                }
            }

            Item {
                width: parent.width
                height: 20
                visible: Notifications.count > 0

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "clear all"
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.sizeSmall
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.clearAll()
                }
            }
        }
    }
}
