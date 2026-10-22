import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import QtQuick
import "../theme"

// Owns org.freedesktop.Notifications and shows toasts top-right.
Scope {
    id: root

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        imageSupported: true
        actionsSupported: true

        onNotification: (n) => { n.tracked = true }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: popup

            property var modelData
            screen: modelData

            anchors {
                top: true
                right: true
            }
            margins {
                top: Theme.barHeight + Theme.gap * 2
                right: Theme.gap
            }
            implicitWidth: 330
            implicitHeight: column.implicitHeight
            visible: server.trackedNotifications.values.length > 0
            color: "transparent"
            exclusiveZone: 0
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "niri-shell-notifications"

            Column {
                id: column
                width: parent.width
                spacing: 8

                Repeater {
                    model: server.trackedNotifications

                    Rectangle {
                        id: note

                        width: column.width
                        implicitHeight: body.implicitHeight + 24
                        radius: 10
                        color: Theme.bgPanel
                        border.width: 1
                        border.color: modelData.urgency === NotificationUrgency.Critical ? Theme.red : Theme.border

                        Column {
                            id: body
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 4

                            Text {
                                width: parent.width
                                text: modelData.appName || "notification"
                                color: Theme.accent
                                font.family: Theme.font
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Text {
                                width: parent.width
                                text: modelData.summary
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: Theme.size
                                font.bold: true
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

                        Timer {
                            interval: (modelData.expireTimeout > 0 ? modelData.expireTimeout : 6) * 1000
                            running: true
                            onTriggered: modelData.dismiss()
                        }
                    }
                }
            }
        }
    }
}
