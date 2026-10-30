pragma Singleton

import QtQuick

QtObject {
    readonly property color bg: "#0b0b0b"
    readonly property color bgBar: "#ee111111"
    readonly property color bgPanel: "#f2161616"
    readonly property color bgHover: "#24ffffff"
    readonly property color surface: "#14ffffff"
    readonly property color accentSoft: "#2effffff"
    readonly property color border: "#40ffffff"

    readonly property color fg: "#f0f0f0"
    readonly property color fgDim: "#b8b8b8"

    readonly property color accent: "#d8d8d8"
    readonly property color accent2: "#9a9a9a"
    readonly property color red: "#b8b8b8"
    readonly property color green: "#b8b8b8"
    readonly property color yellow: "#c8c8c8"
    readonly property color blue: "#a8a8a8"

    readonly property color deskText: "#f0f0f0"
    readonly property color deskTextDim: "#b8b8b8"
    readonly property color deskInk: "#141414"
    readonly property color deskPanel: "#e6141414"
    readonly property color deskPanelSolid: "#161616"
    readonly property color deskBorder: "#4a4a4a"
    readonly property color deskHighlight: "#f0f0f0"
    readonly property color deskShadow: "#99000000"
    readonly property color deskBlue: "#9a9a9a"

    readonly property color barPill: "#4f0d0d0d"
    readonly property color barGlass: "#4d0d0d0d"
    readonly property color barGlassBorder: "#40ffffff"
    readonly property color barScrimTop: "#400d0d0d"
    readonly property color barScrimMid: "#0d0d0d0d"

    readonly property int barWidth: 42
    readonly property int barHeight: 32
    readonly property int taskbarHeight: 32
    readonly property int radius: 0
    readonly property int gap: 8

    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property string fontRetro: "Nimbus Mono PS"
    readonly property int sizeSmall: 9
    readonly property int size: 11
    readonly property int sizeBig: 12
    readonly property int sizeTitle: 16
    readonly property int iconSize: 15

    readonly property int duration: 140
    readonly property int durationSlow: 260

    readonly property string gApps: "\uF009"
    readonly property string gArch: "\uF303"
    readonly property string gPower: "\uF011"
    readonly property string gBell: "\uF0F3"
    readonly property string gChevronLeft: "\uF053"
    readonly property string gChevronRight: "\uF054"
    readonly property string gSettings: "\uF013"
    readonly property string gArrowLeft: "\uF060"
    readonly property string gArrowRight: "\uF061"
    readonly property string gClose: "\uF00D"
    readonly property string gPrev: "\uF048"
    readonly property string gPlay: "\uF04B"
    readonly property string gPause: "\uF04C"
    readonly property string gNext: "\uF051"
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
