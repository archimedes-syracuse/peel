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

    // Codec resolution order: explicit metadata from the player, then a file
    // extension (local files, HLS/DASH), and only then a truthful fallback.
    // A browser player that exposes no codec shows "WEB".
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
        // "codecs=av01.0.05M.08,opus" -> keep a single recognisable token.
        text = text.split(",")[0].trim();
        const compact = text.replace(/[^a-z0-9]+/g, "");

        // Order matters: match the more specific names before the generic ones
        // (e.g. mpeg4 before mpeg, hevc before nothing-else).
        const table = [
            ["flac", "FLAC"], ["opus", "OPUS"], ["vorbis", "VORBIS"],
            ["alac", "ALAC"], ["mp4a", "AAC"], ["aac", "AAC"],
            ["eac3", "AC3"], ["ac3", "AC3"], ["ac4", "AC4"],
            ["dts", "DTS"], ["truehd", "TRUEHD"], ["mlp", "MLP"],
            ["wma", "WMA"], ["amr", "AMR"], ["ape", "APE"], ["dsd", "DSD"],
            ["av01", "AV1"], ["av1", "AV1"], ["vp9", "VP9"], ["vp09", "VP9"],
            ["vp8", "VP8"], ["hevc", "HEVC"], ["h265", "HEVC"],
            ["avc1", "H264"], ["avc", "H264"], ["h264", "H264"],
            ["mpeg4", "MP4"], ["mp4", "MP4"], ["m4v", "MP4"],
            ["mpeg2", "MPEG2"], ["theora", "THEORA"],
            ["webm", "WEBM"], ["matroska", "MKV"], ["mkv", "MKV"],
            ["mpeg", "MP3"], ["mp3", "MP3"],
            ["pcm", "PCM"], ["wav", "WAV"], ["aiff", "AIFF"],
        ];
        for (let i = 0; i < table.length; i++) {
            if (compact.indexOf(table[i][0]) !== -1)
                return table[i][1];
        }
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

    // ── playback position ────────────────────────────────────────────────
    // Firefox's MPRIS reports Position as 0 and never updates it, so reading
    // the player directly leaves the bar clock frozen. Advance a local clock
    // while the player reports playing, and snap to the player's own position
    // whenever it actually moves (real players like mpv, or a seek).
    property real position: 0
    property bool _rawReliable: false
    property real _lastRaw: 0
    property real _lastMs: 0
    property real _lastRawChangeMs: 0
    property bool _wasPlaying: false

    onPlayerChanged: resetPosition()

    function resetPosition() {
        position = player ? (player.position || 0) : 0;
        _rawReliable = false;
        _lastRaw = position;
        _lastMs = Date.now();
        _lastRawChangeMs = _lastMs;
        _wasPlaying = player ? player.isPlaying : false;
    }

    function tickPosition() {
        const p = player;
        if (!p) {
            position = 0;
            return;
        }

        const now = Date.now();
        const raw = p.position || 0;
        const len = p.length || 0;

        // A changing position means the player actually tracks time (mpv,
        // Chromium, some Firefox sites); a frozen one is the Firefox case we
        // have to estimate ourselves.
        if (Math.abs(raw - _lastRaw) > 0.2) {
            _rawReliable = true;
            _lastRawChangeMs = now;
        }
        _lastRaw = raw;

        if (p.isPlaying) {
            if (_rawReliable)
                // extrapolate from the last real sample so the clock is smooth
                position = raw + (now - _lastRawChangeMs) / 1000;
            else if (_wasPlaying)
                position = position + (now - _lastMs) / 1000;
        }

        if (len > 0 && position > len)
            position = len;
        if (position < 0)
            position = 0;

        _lastMs = now;
        _wasPlaying = p.isPlaying;
    }

    Timer {
        interval: 500
        repeat: true
        running: root.player !== null && root.player.isPlaying
        onTriggered: root.tickPosition()
    }

    Connections {
        target: root.player
        ignoreUnknownSignals: true

        function onTrackTitleChanged() {
            root.resetPosition();
        }

        function onPositionChanged() {
            const raw = root.player ? (root.player.position || 0) : 0;
            if (raw > root._lastRaw + 0.2)
                root._rawReliable = true;
        }
    }
}
