pragma Singleton

import QtQuick

// Terminal monochrome: near-black surfaces, grey hairlines, and plain text.
// No color accents, no decorative imagery. The shell should read like a tiling
// window manager with a text UI, not a themed desktop.
QtObject {
    // surfaces
    readonly property color bg: "#0b0b0b"
    readonly property color bgBar: "#ee111111"
    readonly property color bgPanel: "#f2161616"
    readonly property color bgHover: "#24ffffff"
    readonly property color surface: "#14ffffff"
    readonly property color accentSoft: "#2effffff"
    readonly property color border: "#40ffffff"

    // text
    readonly property color fg: "#f0f0f0"
    readonly property color fgDim: "#b8b8b8"

    // accents are deliberately desaturated; callers keep their old semantic
    // names so the rest of the shell does not need a parallel palette.
    readonly property color accent: "#d8d8d8"
    readonly property color accent2: "#9a9a9a"
    readonly property color red: "#b8b8b8"
    readonly property color green: "#b8b8b8"
    readonly property color yellow: "#c8c8c8"
    readonly property color blue: "#a8a8a8"

    // Desktop-scene palette
    readonly property color deskText: "#f0f0f0"
    readonly property color deskTextDim: "#b8b8b8"
    readonly property color deskInk: "#141414"
    readonly property color deskPanel: "#e6141414"
    readonly property color deskPanelSolid: "#161616"
    readonly property color deskBorder: "#4a4a4a"
    readonly property color deskHighlight: "#f0f0f0"
    readonly property color deskShadow: "#99000000"
    readonly property color deskBlue: "#9a9a9a"

    // Top-bar glass. A vertical scrim fades the wallpaper into the strip (see
    // barScrimTop/barScrimMid below) and each module is a square, translucent
    // dark pill with a faint light hairline so the text stays legible over any
    // wallpaper.
    // `barPill` is the stronger tint used by the top bar, whose tiny 14px text
    // sits directly on the (often bright) wallpaper; `barGlass` is the lighter
    // tint shared by the launcher and the overlays, which have larger text and
    // sit over app content.
    readonly property color barPill: "#8c0d0d0d"
    readonly property color barGlass: "#4d0d0d0d"
    readonly property color barGlassBorder: "#40ffffff"
    // The top strip fades into the wallpaper with a scrim instead of a hard
    // edge. `barScrimTop` is the same tint as the pills; it reaches zero
    // opacity at the bottom of the bar.
    readonly property color barScrimTop: "#8c0d0d0d"
    readonly property color barScrimMid: "#380d0d0d"

    // geometry
    // The old rail is kept for reference; the active shell uses the top bar
    // dimensions below. barHeight matches the real top-strip surface.
    readonly property int barWidth: 42
    readonly property int barHeight: 32
    readonly property int taskbarHeight: 32
    readonly property int radius: 0
    readonly property int gap: 8

    // type
    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property string fontRetro: "Nimbus Mono PS"
    readonly property int sizeSmall: 9
    readonly property int size: 11
    readonly property int sizeBig: 12
    readonly property int sizeTitle: 16
    readonly property int iconSize: 15

    // motion
    readonly property int duration: 140
    readonly property int durationSlow: 260

    // Nerd Font glyphs (same codepoints as the existing bar)
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
