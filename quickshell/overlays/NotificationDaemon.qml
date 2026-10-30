import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import QtQuick
import "../theme"
import "../components"
import "../services"

Scope {
    id: root

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
                top: Theme.gap
                right: Theme.gap
            }
            implicitWidth: 304
            implicitHeight: column.implicitHeight
            visible: Notifications.count > 0
            color: "transparent"
            exclusiveZone: 0
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "niri-shell-notifications"

            Column {
                id: column
                width: parent.width
                spacing: 8

                Repeater {
                    model: Notifications.tracked

                    GlassPanel {
                        id: note

                        width: column.width
                        implicitHeight: body.implicitHeight + 20
                        radius: Theme.radius
                        borderWidth: 1
                        fill: Theme.barGlass
                        borderStart: modelData.urgency === NotificationUrgency.Critical ? Theme.red : Theme.accent
                        borderEnd: modelData.urgency === NotificationUrgency.Critical ? Theme.red : Theme.accent2

                        Column {
                            id: body
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4

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
                                font.pixelSize: Theme.sizeBig
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
