import QtQuick

// Courier-style pixel text used by the desktop widgets. Native rendering keeps
// the small point sizes crisp instead of turning them into grey mush.
Text {
    font.family: "Nimbus Mono PS"
    font.pixelSize: 10
    font.bold: true
    font.hintingPreference: Font.PreferFullHinting
    renderType: Text.NativeRendering
    color: "#2e3436"
    wrapMode: Text.NoWrap
}
