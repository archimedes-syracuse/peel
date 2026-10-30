import QtQuick
import "../theme"
import "../services"

BarButton {
    id: root

    glyph: Network.kind === "wifi" ? Theme.gWifi
         : Network.kind === "ethernet" ? Theme.gLan
         : Theme.gOffline
    label: ""
    textColor: Network.online ? Theme.fg : Theme.fgDim
}
