// ==UserScript==
// @name         nowplaying codec bridge
// @namespace    niri-rice-mango
// @version      2.1.0
// @description  Publish the real audio codec of whatever is playing to MPRIS so the desktop bar shows OPUS/AAC/MP3 instead of a generic WEB label.
// @match        *://*/*
// @run-at       document-start
// @grant        none
// ==/UserScript==

// MPRIS has no codec field, and a web page cannot touch the filesystem. The
// one channel a page can reach the desktop through is the MediaSession API:
// Firefox mirrors navigator.mediaSession.metadata to MPRIS, including the
// album slot (xesam:album). This script puts the real audio codec there while
// media plays, and the bar reads it only for browser players.
//
// Where the codec comes from, in order:
//   1. MediaSource buffers. Every MSE player must declare its mime type, e.g.
//      `audio/webm; codecs="opus"` or `audio/mp4; codecs="mp4a.40.2"`.
//   2. Media network responses (fetch/XHR). A player that streams progressively
//      or over HLS still declares a Content-Type such as `audio/mpeg`. This is
//      what catches sites that do not use MSE (e.g. SoundCloud progressive).
//   3. YouTube's own getStatsForNerds().
//   4. A plain <audio>/<video> element with a file extension.
(function () {
    "use strict";

    var AUDIO_TOKENS = {
        OPUS: 1, VORBIS: 1, FLAC: 1, ALAC: 1, AAC: 1, AC3: 1, AC4: 1,
        DTS: 1, TRUEHD: 1, MLP: 1, WMA: 1, AMR: 1, APE: 1, DSD: 1,
        MP3: 1, PCM: 1, WAV: 1, AIFF: 1
    };

    function tokenize(raw) {
        var text = String(raw || "").toLowerCase();
        if (!text)
            return "";
        if (text.indexOf("opus") !== -1) return "OPUS";
        if (text.indexOf("vorbis") !== -1) return "VORBIS";
        if (text.indexOf("flac") !== -1) return "FLAC";
        if (text.indexOf("alac") !== -1) return "ALAC";
        if (text.indexOf("mp4a") !== -1 || text.indexOf("aac") !== -1) return "AAC";
        if (text.indexOf("ec-3") !== -1 || text.indexOf("eac3") !== -1
            || text.indexOf("ac-3") !== -1 || text.indexOf("ac3") !== -1) return "AC3";
        if (text.indexOf("ac-4") !== -1 || text.indexOf("ac4") !== -1) return "AC4";
        if (text.indexOf("dts") !== -1) return "DTS";
        if (text.indexOf("truehd") !== -1) return "TRUEHD";
        if (text.indexOf("wma") !== -1) return "WMA";
        if (text.indexOf("amr") !== -1) return "AMR";
        if (text.indexOf("ape") !== -1) return "APE";
        if (text.indexOf("dsd") !== -1) return "DSD";
        if (text.indexOf("mp3") !== -1 || text.indexOf("mpeg") !== -1
            || text.indexOf("mpeg3") !== -1) return "MP3";
        if (text.indexOf("pcm") !== -1) return "PCM";
        if (text.indexOf("wav") !== -1) return "WAV";
        if (text.indexOf("aiff") !== -1) return "AIFF";
        if (text.indexOf("av01") !== -1) return "AV1";
        if (text.indexOf("av1") !== -1) return "AV1";
        if (text.indexOf("vp09") !== -1 || text.indexOf("vp9") !== -1) return "VP9";
        if (text.indexOf("vp8") !== -1) return "VP8";
        if (text.indexOf("hevc") !== -1 || text.indexOf("h265") !== -1) return "HEVC";
        if (text.indexOf("avc1") !== -1 || text.indexOf("h264") !== -1) return "H264";
        return "";
    }

    // A mime like `audio/mp4; codecs="mp4a.40.2"` or a bare container.
    function codecFromMime(mime) {
        var s = String(mime || "").toLowerCase();
        if (!s)
            return "";
        var match = /codecs?\s*=\s*"?([^";]+)"?/.exec(s);
        if (match) {
            var candidates = match[1].split(",");
            var first = "";
            for (var i = 0; i < candidates.length; i++) {
                var tok = tokenize(candidates[i]);
                if (!tok)
                    continue;
                if (AUDIO_TOKENS[tok])
                    return tok;             // an audio codec wins
                if (!first)
                    first = tok;
            }
            if (first)
                return first;
        }

        // No explicit codecs= param: infer from the container.
        var container = s.split(";")[0].trim();
        if (/audio\/(mp4|mpeg4|m4a|mp4a)/.test(container)) return "AAC";
        if (/audio\/(mpeg|mp3|mpeg3)/.test(container)) return "MP3";
        if (/audio\/aac/.test(container)) return "AAC";
        if (/audio\/(x-)?flac/.test(container)) return "FLAC";
        if (/audio\/ogg/.test(container)) return "VORBIS";
        if (/audio\/webm/.test(container)) return "VORBIS";
        if (/audio\/wav/.test(container)) return "WAV";
        if (/audio\/aiff/.test(container)) return "AIFF";
        return tokenize(container);
    }

    // ── 1. MediaSource buffers ──────────────────────────────────────────
    var buffers = [];

    try {
        var ms = window.MediaSource && window.MediaSource.prototype;
        if (ms && typeof ms.addSourceBuffer === "function") {
            var origAdd = ms.addSourceBuffer;
            ms.addSourceBuffer = function (mime) {
                try {
                    buffers.push(String(mime));
                    if (buffers.length > 40)
                        buffers.shift();
                } catch (e) {}
                return origAdd.apply(this, arguments);
            };
        }
    } catch (e) {}

    function codecFromBuffers() {
        var fallback = "";
        for (var i = buffers.length - 1; i >= 0; i--) {
            var mime = buffers[i];
            if (/^audio\//i.test(mime)) {
                var audio = codecFromMime(mime);
                if (audio)
                    return audio;           // an audio-declared buffer wins
            } else if (!fallback) {
                fallback = codecFromMime(mime);
            }
        }
        return fallback;
    }

    // ── 2. Media network responses ──────────────────────────────────────
    var mediaTypes = [];

    function recordMediaType(url, contentType) {
        var type = String(contentType || "").toLowerCase();
        if (!type)
            return;
        var isMedia = /^audio\//.test(type) || /^video\//.test(type)
            || (type.indexOf("application/octet-stream") === 0 && /\.(mp3|m4a|aac|ogg|opus|flac|wav)(\?|$)/i.test(url || ""));
        if (isMedia) {
            mediaTypes.push(type);
            if (mediaTypes.length > 40)
                mediaTypes.shift();
        }
    }

    try {
        if (typeof window.fetch === "function") {
            var origFetch = window.fetch;
            window.fetch = function (input, init) {
                var url = (input && input.url) || String(input || "");
                var p = origFetch.apply(this, arguments);
                try {
                    p.then(function (res) {
                        try {
                            recordMediaType(url, res.headers.get("content-type"));
                        } catch (e) {}
                    });
                } catch (e) {}
                return p;
            };
        }
    } catch (e) {}

    try {
        var origOpen = XMLHttpRequest.prototype.open;
        var origSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.open = function (method, url) {
            try {
                this.__codecUrl = url;
            } catch (e) {}
            return origOpen.apply(this, arguments);
        };
        XMLHttpRequest.prototype.send = function () {
            var xhr = this;
            try {
                xhr.addEventListener("load", function () {
                    try {
                        recordMediaType(xhr.__codecUrl, xhr.getResponseHeader("content-type"));
                    } catch (e) {}
                });
            } catch (e) {}
            return origSend.apply(this, arguments);
        };
    } catch (e) {}

    function codecFromNetwork() {
        var fallback = "";
        for (var i = mediaTypes.length - 1; i >= 0; i--) {
            var type = mediaTypes[i];
            if (/^audio\//.test(type)) {
                var audio = codecFromMime(type);
                if (audio)
                    return audio;
            } else if (!fallback) {
                fallback = codecFromMime(type);
            }
        }
        return fallback;
    }

    // ── 3. YouTube's own stats ──────────────────────────────────────────
    function codecFromYouTube() {
        var player = document.getElementById("movie_player");
        if (!player || typeof player.getStatsForNerds !== "function")
            return "";
        var stats;
        try {
            stats = player.getStatsForNerds();
        } catch (e) {
            return "";
        }
        if (!stats)
            return "";
        var parts = [];
        ["codecs", "codec", "audioCodecs", "audioCodec"].forEach(function (key) {
            if (stats[key])
                parts.push(String(stats[key]));
        });
        var raw = parts.join(" / ");
        var audio = raw.indexOf("/") !== -1 ? raw.split("/").pop() : raw;
        var codec = tokenize(audio);
        if (codec)
            return codec;
        try {
            return tokenize(JSON.stringify(stats));
        } catch (e) {
            return "";
        }
    }

    // ── 4. A plain media element with a file URL ─────────────────────────
    function codecFromElement() {
        var el = document.querySelector("audio, video");
        var src = el && (el.currentSrc || el.src) || "";
        if (!src || src.indexOf("blob:") === 0)
            return "";
        var file = src.split("#")[0].split("?")[0];
        var dot = file.lastIndexOf(".");
        if (dot < 0)
            return "";
        return tokenize(file.substring(dot + 1));
    }

    function audioCodec() {
        return codecFromBuffers() || codecFromNetwork()
            || codecFromYouTube() || codecFromElement();
    }

    // ── Publish to MediaSession metadata (album slot) ────────────────────
    var session = navigator.mediaSession;
    if (!session)
        return;
    var proto = Object.getPrototypeOf(session);
    var desc = Object.getOwnPropertyDescriptor(proto, "metadata");
    if (!desc || !desc.set || !desc.get)
        return;

    var pageMetadata = null;

    function publish() {
        if (!pageMetadata)
            return;
        var codec = audioCodec();
        if (!codec)
            return;
        var native = desc.get.call(session);
        if (native && native.album === codec)
            return;
        desc.set.call(session, new MediaMetadata({
            title: pageMetadata.title,
            artist: pageMetadata.artist,
            album: codec,
            artwork: pageMetadata.artwork
        }));
    }

    Object.defineProperty(session, "metadata", {
        configurable: true,
        enumerable: true,
        get: function () {
            return desc.get.call(session);
        },
        set: function (value) {
            pageMetadata = value;
            desc.set.call(session, value);
            publish();
        }
    });

    // The stream's mime type is often known only a moment after metadata is
    // set, so keep refreshing while media is present.
    setInterval(publish, 2000);
})();
