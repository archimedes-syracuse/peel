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

    readonly property var metadata: player && player.metadata ? player.metadata : ({})

    // MPRIS has no standard codec field. Prefer an explicit codec/format from
    // the player, then a file extension, and only then fall back to a truthful
    // source label. A Firefox video is "WEB", not a made-up FLAC tag.
    readonly property string format: {
        if (!player)
            return "";

        const meta = player.metadata || {};
        const keys = [
            "audio-format", "audio-codec", "audioFormat", "audioCodec",
            "xesam:audioFormat", "xesam:codec", "mpris:audioFormat",
            "media:codec", "codec", "format"
        ];
        for (let i = 0; i < keys.length; i++) {
            const value = firstValue(meta[keys[i]]);
            const codec = normalizeFormat(value);
            if (codec !== "")
                return codec;
        }

        const url = firstValue(meta["xesam:url"])
            || firstValue(meta["url"])
            || firstValue(meta["mpris:artUrl"]);
        const extension = formatFromUrl(url);
        if (extension !== "")
            return extension;

        if (isBrowserPlayer())
            return "WEB";
        return "AUDIO";
    }

    function firstValue(value) {
        if (value === undefined || value === null)
            return "";
        if (typeof value === "object" && value.length !== undefined)
            return String(value[0] || "");
        return String(value);
    }

    function normalizeFormat(value) {
        let text = String(value || "").trim().toLowerCase();
        if (text === "")
            return "";

        // Strip MIME parameters such as "; codecs=opus" and the media type.
        text = text.split(";")[0].trim();
        text = text.replace(/^audio\//, "").replace(/^video\//, "");
        const compact = text.replace(/[^a-z0-9]+/g, "");

        if (compact.indexOf("flac") !== -1)
            return "FLAC";
        if (compact.indexOf("opus") !== -1)
            return "OPUS";
        if (compact.indexOf("vorbis") !== -1)
            return "VORBIS";
        if (compact.indexOf("alac") !== -1)
            return "ALAC";
        if (compact.indexOf("mp4a") !== -1 || compact.indexOf("aac") !== -1)
            return "AAC";
        if (compact.indexOf("mpeg") !== -1 || compact.indexOf("mp3") !== -1)
            return "MP3";
        if (compact.indexOf("pcm") !== -1 || compact.indexOf("wav") !== -1)
            return "PCM";
        if (compact.indexOf("eac3") !== -1 || compact.indexOf("ac3") !== -1)
            return "AC3";
        if (compact.indexOf("dts") !== -1)
            return "DTS";
        if (compact.indexOf("webm") !== -1)
            return "WEBM";
        if (compact.indexOf("mp4") !== -1)
            return "MP4";
        return "";
    }

    function formatFromUrl(value) {
        const url = String(value || "").split("#")[0].split("?")[0];
        const file = url.substring(url.lastIndexOf("/") + 1);
        const dot = file.lastIndexOf(".");
        if (dot < 0 || dot === file.length - 1)
            return "";

        switch (file.substring(dot + 1).toLowerCase()) {
        case "flac": return "FLAC";
        case "mp3": return "MP3";
        case "m4a": return "M4A";
        case "aac": return "AAC";
        case "opus": return "OPUS";
        case "ogg":
        case "oga": return "OGG";
        case "wav": return "WAV";
        case "webm": return "WEBM";
        case "mp4":
        case "m4v": return "MP4";
        case "mkv": return "MKV";
        case "mov": return "MOV";
        case "ts":
        case "m3u8": return "HLS";
        case "mpd": return "DASH";
        default: return "";
        }
    }

    function isBrowserPlayer() {
        const list = players || [];
        for (let i = 0; i < list.length; i++) {
            const identity = String(list[i] && list[i].identity || "").toLowerCase();
            if (identity.indexOf("firefox") !== -1
                    || identity.indexOf("librewolf") !== -1
                    || identity.indexOf("chrom") !== -1
                    || identity.indexOf("brave") !== -1
                    || identity.indexOf("vivaldi") !== -1
                    || identity.indexOf("opera") !== -1
                    || identity.indexOf("edge") !== -1
                    || identity.indexOf("browser") !== -1)
                return true;
        }
        return false;
    }

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
