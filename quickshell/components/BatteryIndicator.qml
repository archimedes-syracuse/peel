import QtQuick
import "../theme"
import "../services"

// Battery glyph + percentage from sysfs.
BarButton {
    id: root

    visible: Battery.present

    function batteryGlyph() {
        if (Battery.charging)
            return Theme.gCharging;
        if (Battery.pct > 90)
            return Theme.gBattFull;
        if (Battery.pct > 60)
            return Theme.gBattThree;
        if (Battery.pct > 35)
            return Theme.gBattHalf;
        if (Battery.pct > 15)
            return Theme.gBattQuarter;
        return Theme.gBattEmpty;
    }

    glyph: batteryGlyph()
    label: Battery.present ? Battery.pct + "%" : ""
    textColor: Battery.low ? Theme.red : Battery.charging ? Theme.green : Theme.fg
}
