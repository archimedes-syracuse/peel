pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// One selection policy for every now-playing surface. Prefer a player that is
// actually playing, otherwise use the first available player.
Singleton {
    id: root

    readonly property var players: Mpris.players ? Mpris.players.values : []
    readonly property var player: {
        const list = players || [];
        for (let i = 0; i < list.length; i++) {
            if (list[i] && list[i].isPlaying)
                return list[i];
        }
        return list.length > 0 ? list[0] : null;
    }

    readonly property string title: player && player.trackTitle ? String(player.trackTitle) : ""
    readonly property string artist: player
        ? String(player.trackArtist || player.identity || "")
        : ""
    readonly property bool available: title !== ""

    // Browser players often expose a generic "LibreWolf is playing media"
    // title with no artist. Keep the desktop card on its illustrated demo
    // state until a real track is available.
    readonly property bool hasTrack: {
        if (!available)
            return false;
        const lower = title.toLowerCase();
        return lower.indexOf(" is playing media") === -1
            && lower !== "firefox"
            && lower !== "librewolf";
    }
}
