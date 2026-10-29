import QtQuick.Effects

// A soft ~2px dark halo behind text so it stays readable on the translucent
// glass surfaces. Attach it to a Text with:
//     layer.enabled: true
//     layer.effect: TextOutline {}
MultiEffect {
    shadowEnabled: true
    shadowColor: "#e6000000"
    shadowBlur: 2
    shadowHorizontalOffset: 0
    shadowVerticalOffset: 0
    shadowOpacity: 1.0
    autoPaddingEnabled: true
}
