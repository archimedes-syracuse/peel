pragma Singleton

import QtQuick

// Palette matched to the compact reference bar: near-black translucent
// surfaces, pink active state, and pale-gold system readouts. Swap these
// values (or generate them with matugen later) and the shell follows.
//
// Visual language: 4px geometry, JetBrains Mono, accent-as-state.
QtObject {
    // surfaces
    readonly property color bg: "#0c0b10"
    readonly property color bgBar: "#ee0c0b10"
    readonly property color bgPanel: "#f217161c"
    readonly property color bgHover: "#1fffffff"
    readonly property color surface: "#0fffffff"
    readonly property color accentSoft: "#40f2a8c4"
    readonly property color border: "#26ffffff"

    // text
    readonly property color fg: "#ded9e2"
    readonly property color fgDim: "#918c98"

    // accents
    readonly property color accent: "#f2a8c4"
    readonly property color accent2: "#c2c1ff"
    readonly property color red: "#ffb4ab"
    readonly property color green: "#b5ccba"
    readonly property color yellow: "#e5c79a"
    readonly property color blue: "#a9c7e8"

    // geometry
    readonly property int barHeight: 30
    readonly property int radius: 4
    readonly property int gap: 8

    // type
    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int sizeSmall: 10
    readonly property int size: 12
    readonly property int sizeBig: 13
    readonly property int sizeTitle: 16
    readonly property int iconSize: 15

    // motion
    readonly property int duration: 150
    readonly property int durationSlow: 300

    // Nerd Font glyphs (same codepoints as the existing bar)
    readonly property string gApps: "\uF009"
    readonly property string gArch: "\uF303"
    readonly property string gPower: "\uF011"
    readonly property string gBell: "\uF0F3"
    readonly property string gChevronLeft: "\uF053"
    readonly property string gBrightness: "\uF185"
    readonly property string gDisk: "\uF0A0"
    readonly property string gRam: "\uF1C0"
    readonly property string gCpu: "\uF2DB"
    readonly property string gVolHigh: "\uF028"
    readonly property string gVolLow: "\uF027"
    readonly property string gMuted: "\uF026"
    readonly property string gWifi: "\uF1EB"
    readonly property string gLan: "\uF1E6"
    readonly property string gOffline: "\uF05E"
    readonly property string gBattFull: "\uF240"
    readonly property string gBattThree: "\uF241"
    readonly property string gBattHalf: "\uF242"
    readonly property string gBattQuarter: "\uF243"
    readonly property string gBattEmpty: "\uF244"
    readonly property string gCharging: "\uF0E7"
    readonly property string gLock: "\uF023"
    readonly property string gSearch: "\uF002"
    readonly property string gBluetooth: "\uF293"
    readonly property string gNote: "\uF001"
    readonly property string gScreenshot: "\uF030"
    readonly property string gTerminal: "\uF120"
    readonly property string gReboot: "\uF021"
    readonly property string gLogout: "\uF08B"
    readonly property string gSuspend: "\uF186"
    readonly property string gShutdown: "\uF011"
}
