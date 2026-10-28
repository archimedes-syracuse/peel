// ==UserScript==
// @name         nowplaying codec bridge (YouTube Music)
// @namespace    niri-rice-mango
// @version      1.0.0
// @description  Publish the real audio codec of the playing track to MPRIS so the desktop bar shows OPUS/AAC instead of a generic WEB label.
// @match        https://music.youtube.com/*
// @match        https://www.youtube.com/*
// @match        https://youtube.com/*
// @match        https://m.youtube.com/*
// @run-at       document-start
// @grant        none
// ==/UserScript==

// MPRIS has no codec field, and a web page cannot touch the filesystem. The
// one channel a page can reach the desktop through is the MediaSession API:
// Firefox mirrors navigator.mediaSession.metadata to MPRIS, including the
// album slot (xesam:album). This script keeps the real audio codec there while
// music plays. The bar reads it only for browser players, so a normal album
// name is never shown as a codec, and web *videos* keep showing "WEB".
(function () {
    "use strict";

    function tokenize(raw) {
        const text = String(raw || "").toLowerCase();
        if (!text)
            return "";
        if (text.includes("opus")) return "OPUS";
        if (text.includes("vorbis")) return "VORBIS";
        if (text.includes("flac")) return "FLAC";
        if (text.includes("ec-3") || text.includes("eac3")
            || text.includes("ac-3") || text.includes("ac3")) return "AC3";
        if (text.includes("ac-4") || text.includes("ac4")) return "AC4";
        if (text.includes("mp4a") || text.includes("aac")) return "AAC";
        if (text.includes("dts")) return "DTS";
        if (text.includes("mp3")) return "MP3";
        return "";
    }

    // YouTube's player exposes the negotiated codecs, e.g.
    // "av01.0.05M.08 / opus" — the audio codec follows the slash.
    function audioCodec() {
        const player = document.getElementById("movie_player");
        if (!player || typeof player.getStatsForNerds !== "function")
            return "";
        let stats;
        try {
            stats = player.getStatsForNerds();
        } catch (e) {
            return "";
        }
        if (!stats)
            return "";
        const raw = String(stats.codecs || stats.audioCodecs || stats.audioCodec || "");
        return tokenize(raw.includes("/") ? raw.split("/").pop() : raw);
    }

    const proto = Object.getPrototypeOf(navigator.mediaSession);
    const desc = Object.getOwnPropertyDescriptor(proto, "metadata");
    if (!desc || !desc.set || !desc.get)
        return;

    let pageMetadata = null;

    function publish() {
        if (!pageMetadata)
            return;
        const codec = audioCodec();
        if (!codec)
            return;
        const native = desc.get.call(navigator.mediaSession);
        if (native && native.album === codec)
            return;
        desc.set.call(navigator.mediaSession, new MediaMetadata({
            title: pageMetadata.title,
            artist: pageMetadata.artist,
            album: codec,
            artwork: pageMetadata.artwork,
        }));
    }

    Object.defineProperty(navigator.mediaSession, "metadata", {
        configurable: true,
        enumerable: true,
        get() {
            return desc.get.call(navigator.mediaSession);
        },
        set(value) {
            pageMetadata = value;
            desc.set.call(navigator.mediaSession, value);
            publish();
        },
    });

    // The player's stats are sometimes not ready the instant metadata is set.
    setInterval(publish, 2000);
})();
