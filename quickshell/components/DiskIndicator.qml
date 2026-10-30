import QtQuick
import "../theme"
import "../services"

BarButton {
    visible: Disk.available
    glyph: Theme.gDisk
    label: Disk.available ? Disk.pct + "%" : ""
    textColor: Theme.fg
    glyphColor: Theme.fgDim
}
