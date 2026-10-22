import QtQuick
import "../theme"
import "../services"

// Memory load readout, updated by the shared SysStats sampler.
BarButton {
    glyph: Theme.gRam
    label: Math.round(SysStats.mem) + "%"
    textColor: Theme.fg
    glyphColor: Theme.fgDim
}
