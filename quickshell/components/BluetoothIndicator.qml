import QtQuick
import "../theme"
import "../services"

BarButton {
    id: root

    visible: Bluetooth.available
    glyph: Theme.gBluetooth
    label: Bluetooth.connectedCount > 0 ? String(Bluetooth.connectedCount) : ""
    textColor: Bluetooth.powered ? Theme.fg : Theme.fgDim
}
