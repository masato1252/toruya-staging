"use strict"

import React, { useState, useRef, useEffect, useCallback } from "react";

const isYoutubeUrl = (url) => !!url && /(?:youtube\.com|youtu\.be)/.test(url);
const isDriveUrl = (url) => url && /(?:drive|docs)\.google\.com/.test(url);

const getEmbedUrl = (url) => {
  if (!url) return null;

  const ytMatch = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/);
  if (ytMatch) {
    const origin = typeof window !== "undefined" ? window.location.origin : "";
    const params = [
      "autoplay=1",
      "rel=0",
      "modestbranding=1",
      "iv_load_policy=3",
      "playsinline=1",
      "fs=1",
      "disablekb=1",
      "enablejsapi=1",
      `origin=${encodeURIComponent(origin)}`
    ].join("&");
    return `https://www.youtube-nocookie.com/embed/${ytMatch[1]}?${params}`;
  }

  if (/(?:drive|docs)\.google\.com/.test(url)) {
    let driveId = null;
    const fileMatch = url.match(/\/file\/d\/([a-zA-Z0-9_-]+)/);
    if (fileMatch) driveId = fileMatch[1];
    if (!driveId) {
      const idParamMatch = url.match(/[?&]id=([a-zA-Z0-9_-]+)/);
      if (idParamMatch) driveId = idParamMatch[1];
    }
    if (driveId) return `https://drive.google.com/file/d/${driveId}/preview`;
    console.warn("[EventContent] Google Drive URL の形式を認識できませんでした:", url);
  }

  return url;
};

// "M/D(曜日) HH:MM" 形式で日時をフォーマット。コンテンツ詳細の配信開始表示で使う。
const formatJaDateTimeShort = (value) => {
  if (!value) return null;
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return null;
  const weekdays = ["日", "月", "火", "水", "木", "金", "土"];
  const pad = (n) => String(n).padStart(2, "0");
  return `${d.getMonth() + 1}/${d.getDate()}(${weekdays[d.getDay()]}) ${pad(d.getHours())}:${pad(d.getMinutes())}`;
};

// 出展者・出演者の自己紹介文中の http(s) URL を <a> 要素に変換するヘルパ。
// テキスト末尾に付いた句読点や閉じ括弧は URL から外して trailing として保持する。
const URL_REGEX = /(https?:\/\/[^\s]+)/g;
const URL_TRAILING_PUNCT = /[、。！？!?.,;:）)」』】〉》"']+$/;

const linkifyText = (text) => {
  if (!text) return text;
  const parts = text.split(URL_REGEX);
  return parts.map((part, idx) => {
    if (/^https?:\/\//.test(part)) {
      let url = part;
      let trailing = "";
      const m = url.match(URL_TRAILING_PUNCT);
      if (m) {
        trailing = m[0];
        url = url.slice(0, url.length - trailing.length);
      }
      return (
        <React.Fragment key={idx}>
          <a
            href={url}
            target="_blank"
            rel="noopener noreferrer"
            style={{ color: "#488479", textDecoration: "underline", wordBreak: "break-all" }}
          >
            {url}
          </a>
          {trailing}
        </React.Fragment>
      );
    }
    return <React.Fragment key={idx}>{part}</React.Fragment>;
  });
};

let ytApiPromise = null;
const loadYouTubeIframeApi = () => {
  if (typeof window === "undefined") return Promise.resolve(null);
  if (window.YT && window.YT.Player) return Promise.resolve(window.YT);
  if (ytApiPromise) return ytApiPromise;

  ytApiPromise = new Promise((resolve) => {
    const prev = window.onYouTubeIframeAPIReady;
    window.onYouTubeIframeAPIReady = () => {
      if (typeof prev === "function") { try { prev(); } catch (_) {} }
      resolve(window.YT);
    };
    if (!document.querySelector('script[src*="youtube.com/iframe_api"]')) {
      const script = document.createElement("script");
      script.src = "https://www.youtube.com/iframe_api";
      script.async = true;
      document.body.appendChild(script);
    }
  });
  return ytApiPromise;
};

const EventLineLoginLink = ({ loginUrl, btnText, style }) => {
  if (!loginUrl) return null;

  return (
    <a
      href={loginUrl}
      style={{
        display: "inline-flex", alignItems: "center", gap: 8,
        padding: "14px 28px", background: "#06c755", color: "#fff",
        borderRadius: 30, fontSize: 15, fontWeight: "bold",
        textDecoration: "none", cursor: "pointer", boxShadow: "0 4px 14px rgba(6,199,85,0.4)",
        width: "100%", justifyContent: "center",
        ...style
      }}
    >
      <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M19.365 9.863c.349 0 .63.285.63.631 0 .345-.281.63-.63.63H17.61v1.125h1.755c.349 0 .63.283.63.63 0 .344-.281.629-.63.629h-2.386c-.345 0-.627-.285-.627-.629V8.108c0-.345.282-.63.63-.63h2.386c.346 0 .627.285.627.63 0 .349-.281.63-.63.63H17.61v1.125h1.755zm-3.855 3.016c0 .27-.174.51-.432.596-.064.021-.133.031-.199.031-.211 0-.391-.09-.51-.25l-2.443-3.317v2.94c0 .344-.279.629-.631.629-.346 0-.626-.285-.626-.629V8.108c0-.27.173-.51.43-.595.06-.023.136-.033.194-.033.195 0 .375.104.495.254l2.462 3.33V8.108c0-.345.282-.63.63-.63.345 0 .63.285.63.63v4.771zm-5.741 0c0 .344-.282.629-.631.629-.345 0-.627-.285-.627-.629V8.108c0-.345.282-.63.63-.63.346 0 .628.285.628.63v4.771zm-2.466.629H4.917c-.345 0-.63-.285-.63-.629V8.108c0-.345.285-.63.63-.63.348 0 .63.285.63.63v4.141h1.756c.348 0 .629.283.629.63 0 .344-.282.629-.629.629M24 10.314C24 4.943 18.615.572 12 .572S0 4.943 0 10.314c0 4.811 4.27 8.842 10.035 9.608.391.082.923.258 1.058.59.12.301.079.766.038 1.08l-.164 1.02c-.045.301-.24 1.186 1.049.645 1.291-.539 6.916-4.078 9.436-6.975C23.176 14.393 24 12.458 24 10.314"/></svg>
      {btnText}
    </a>
  );
};

const PlatformIcon = ({ name }) => {
  const s = { width: 22, height: 22 };
  switch (name) {
    case "facebook":
      return <svg style={s} viewBox="0 0 24 24" fill="currentColor"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>;
    case "x":
      return <svg style={s} viewBox="0 0 24 24" fill="currentColor"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg>;
    case "instagram":
      return <svg style={s} viewBox="0 0 24 24" fill="currentColor"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/></svg>;
    case "linkedin":
      return <svg style={s} viewBox="0 0 24 24" fill="currentColor"><path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433a2.062 2.062 0 01-2.063-2.065 2.064 2.064 0 112.063 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/></svg>;
    default:
      return null;
  }
};

const ShareModal = ({ isOpen, onClose, title, shareTitle, thumbnailUrl, shareUrl }) => {
  const [copied, setCopied] = useState(false);
  if (!isOpen) return null;

  const encodedUrl = encodeURIComponent(shareUrl);
  const encodedTitle = encodeURIComponent(shareTitle);

  const handleCopy = () => {
    navigator.clipboard.writeText(shareUrl).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };

  const platforms = [
    { name: "facebook", label: "Facebook", href: `https://www.facebook.com/sharer/sharer.php?u=${encodedUrl}` },
    { name: "x", label: "X", href: `https://twitter.com/intent/tweet?text=${encodedTitle}&url=${encodedUrl}` },
    { name: "instagram", label: "Instagram", href: "https://www.instagram.com/" },
    { name: "linkedin", label: "LinkedIn", href: `https://www.linkedin.com/sharing/share-offsite/?url=${encodedUrl}` }
  ];

  return (
    <div
      onClick={onClose}
      style={{
        position: "fixed", top: 0, left: 0, right: 0, bottom: 0,
        background: "rgba(0,0,0,0.6)", zIndex: 9999,
        display: "flex", alignItems: "center", justifyContent: "center",
        padding: 16
      }}
    >
      <div
        onClick={e => e.stopPropagation()}
        style={{
          background: "#fff", borderRadius: 16, width: "100%", maxWidth: 400,
          overflow: "hidden", boxShadow: "0 20px 60px rgba(0,0,0,0.3)"
        }}
      >
        <div style={{
          background: "#488479", color: "#fff", padding: "16px 20px",
          display: "flex", alignItems: "center", justifyContent: "center",
          position: "relative"
        }}>
          <span style={{ fontSize: 15, fontWeight: 700 }}>{title}</span>
          <button
            onClick={onClose}
            style={{
              position: "absolute", right: 12, top: "50%", transform: "translateY(-50%)",
              background: "rgba(255,255,255,0.2)", border: "none", color: "#fff",
              width: 32, height: 32, borderRadius: "50%", cursor: "pointer",
              display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16
            }}
          >
            ✕
          </button>
        </div>

        <div style={{ padding: "24px 20px" }}>
          <div style={{
            overflow: "hidden", marginBottom: 20,
            border: "1px solid #e5e7eb", background: "#fafafa"
          }}>
            {thumbnailUrl && (
              <img src={thumbnailUrl} style={{ width: "100%", height: 160, objectFit: "cover", display: "block" }} />
            )}
            <div style={{ padding: "12px 16px" }}>
              <div style={{ fontWeight: 700, fontSize: 14, color: "#111827", lineHeight: 1.5 }}>{shareTitle}</div>
            </div>
          </div>

          <div style={{
            display: "flex", alignItems: "center", gap: 8, marginBottom: 20,
            background: "#f5f5f4", padding: "10px 14px"
          }}>
            <input
              readOnly
              value={shareUrl}
              style={{
                flex: 1, border: "none", background: "transparent", fontSize: 13,
                color: "#374151", outline: "none", minWidth: 0
              }}
            />
          </div>

          <button
            onClick={handleCopy}
            style={{
              width: "100%", padding: "12px", border: "1px solid #d1d5db",
              borderRadius: 10, background: "#fff", cursor: "pointer",
              display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
              fontSize: 14, color: "#374151", fontWeight: 600, marginBottom: 20
            }}
          >
            <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor"><path d="M8 3a1 1 0 011-1h2a1 1 0 110 2H9a1 1 0 01-1-1z"/><path d="M6 3a2 2 0 00-2 2v11a2 2 0 002 2h8a2 2 0 002-2V5a2 2 0 00-2-2 3 3 0 01-3 3H9a3 3 0 01-3-3z"/></svg>
            {copied ? "コピーしました" : "URLをコピー"}
          </button>

          <div style={{
            display: "flex", justifyContent: "center", gap: 24,
            borderTop: "1px solid #e5e7eb", paddingTop: 20
          }}>
            {platforms.map(p => (
              <a
                key={p.name}
                href={p.href}
                target="_blank"
                rel="noopener noreferrer"
                style={{
                  display: "flex", flexDirection: "column", alignItems: "center", gap: 6,
                  textDecoration: "none", color: "#374151"
                }}
              >
                <div style={{
                  width: 48, height: 48, borderRadius: "50%", border: "1px solid #e5e7eb",
                  display: "flex", alignItems: "center", justifyContent: "center"
                }}>
                  <PlatformIcon name={p.name} />
                </div>
                <span style={{ fontSize: 11, fontWeight: 500 }}>{p.label}</span>
              </a>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

const VideoPlayer = ({ preAdUrl, contentUrl, postAdUrl, onComplete, onMainPhaseStart, fullHeight = false }) => {
  const [phase, setPhase] = useState(preAdUrl ? "pre_ad" : "main");
  const [iframeKey, setIframeKey] = useState(0);
  const mainFired = useRef(!preAdUrl);
  const iframeRef = useRef(null);
  const playerRef = useRef(null);
  const nextPhaseRef = useRef(null);

  useEffect(() => {
    if (phase === "main" && !mainFired.current) {
      mainFired.current = true;
      onMainPhaseStart && onMainPhaseStart();
    }
  }, [phase]);

  const currentUrl = phase === "pre_ad" ? preAdUrl
    : phase === "main" ? contentUrl
    : postAdUrl;

  const nextPhase = () => {
    if (phase === "pre_ad") { setPhase("main"); setIframeKey(k => k + 1); }
    else if (phase === "main") {
      if (postAdUrl) { setPhase("post_ad"); setIframeKey(k => k + 1); }
      else { onComplete && onComplete(); }
    } else {
      onComplete && onComplete();
    }
  };
  nextPhaseRef.current = nextPhase;

  const phaseLabel = phase === "pre_ad" ? "広告" : phase === "main" ? "セミナー講演本編" : "広告";
  const isDrive = isDriveUrl(currentUrl);
  const isYoutube = isYoutubeUrl(currentUrl);

  useEffect(() => {
    if (!isYoutube || !iframeRef.current) return;

    let cancelled = false;
    loadYouTubeIframeApi().then((YT) => {
      if (cancelled || !iframeRef.current || !YT) return;
      try {
        playerRef.current = new YT.Player(iframeRef.current, {
          events: {
            onStateChange: (e) => {
              if (e.data === YT.PlayerState.ENDED) {
                if (nextPhaseRef.current) nextPhaseRef.current();
              }
            }
          }
        });
      } catch (err) {
        console.warn("[EventContent] YT.Player init failed:", err);
      }
    });

    return () => {
      cancelled = true;
      if (playerRef.current) {
        try { playerRef.current.destroy(); } catch (_) {}
        playerRef.current = null;
      }
    };
  }, [iframeKey, isYoutube]);

  const videoAreaStyle = fullHeight
    ? { position: "relative", flex: 1, minHeight: 0 }
    : { position: "relative", paddingBottom: "56.25%" };

  return (
    <div style={{
      background: "#000", overflow: "hidden",
      ...(fullHeight ? { display: "flex", flexDirection: "column", height: "100%" } : {})
    }}>
      <div style={{ padding: "8px 14px", background: "rgba(255,255,255,0.08)", display: "flex", justifyContent: "space-between", alignItems: "center", flexShrink: 0 }}>
        <span style={{ color: "#fff", fontSize: 12, fontWeight: 600 }}>{phaseLabel}</span>
        <button onClick={nextPhase} style={{ background: "rgba(255,255,255,0.15)", color: "#fff", border: "none", borderRadius: 6, padding: "5px 14px", cursor: "pointer", fontSize: 12, fontWeight: 600 }}>
          {phase === "post_ad" ? "完了" : "次へ ▶"}
        </button>
      </div>
      <div style={videoAreaStyle}>
        <iframe
          key={iframeKey}
          ref={iframeRef}
          src={getEmbedUrl(currentUrl)}
          frameBorder="0"
          allowFullScreen
          allow="autoplay; fullscreen; encrypted-media; picture-in-picture"
          referrerPolicy="no-referrer-when-downgrade"
          style={{ position: "absolute", top: 0, left: 0, width: "100%", height: "100%" }}
        />
        {isYoutube && (
          <>
            {/* 左上: タイトル2行分をブロック。右側 110px は音量/設定ボタン用に残す */}
            <div
              onClick={(e) => e.preventDefault()}
              onContextMenu={(e) => e.preventDefault()}
              style={{
                position: "absolute", top: 0, left: 0,
                width: "calc(100% - 110px)", height: 72,
                background: "transparent", pointerEvents: "auto", zIndex: 2,
                cursor: "default"
              }}
            />
            {/* 右下: 「その他の動画」+「YouTube」ロゴをブロック。最右端 48px は全画面ボタン用に残す */}
            <div
              onClick={(e) => e.preventDefault()}
              onContextMenu={(e) => e.preventDefault()}
              style={{
                position: "absolute", bottom: 0, right: 48,
                width: 280, height: 56,
                background: "transparent", pointerEvents: "auto", zIndex: 2,
                cursor: "default"
              }}
            />
            {/* 左下: 共有リンク（鎖マーク）をブロック。時間表示と重なるが時間表示は非インタラクティブなのでOK */}
            <div
              onClick={(e) => e.preventDefault()}
              onContextMenu={(e) => e.preventDefault()}
              style={{
                position: "absolute", bottom: 0, left: 0,
                width: 56, height: 56,
                background: "transparent", pointerEvents: "auto", zIndex: 2,
                cursor: "default"
              }}
            />
          </>
        )}
      </div>
      {isDrive && (
        <div style={{
          padding: "8px 14px", background: "rgba(252,190,70,0.1)",
          color: "#FCBE46", fontSize: 11, display: "flex", alignItems: "center", justifyContent: "space-between", gap: 8, flexShrink: 0
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: 6, flex: 1, minWidth: 0 }}>
            <svg width="14" height="14" viewBox="0 0 20 20" fill="currentColor" style={{ flexShrink: 0 }}>
              <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd"/>
            </svg>
            <span>再生されない場合は別タブで開いてください</span>
          </div>
          <a
            href={currentUrl}
            target="_blank"
            rel="noopener noreferrer"
            style={{ color: "#FCBE46", fontWeight: 700, textDecoration: "underline", flexShrink: 0 }}
          >
            別タブで開く
          </a>
        </div>
      )}
    </div>
  );
};

const orientationLockSupported = () =>
  typeof window !== "undefined" &&
  window.screen &&
  window.screen.orientation &&
  typeof window.screen.orientation.lock === "function";

const VideoPlayerModal = ({ isOpen, onClose, preAdUrl, contentUrl, postAdUrl, onMainPhaseStart }) => {
  const containerRef = useRef(null);
  const [isMobile, setIsMobile] = useState(false);
  const [orientation, setOrientation] = useState("landscape");
  const fullscreenEnteredRef = useRef(false);

  const enterFullscreen = useCallback(async () => {
    const el = containerRef.current;
    if (!el || document.fullscreenElement) return true;
    const requestFs = el.requestFullscreen
      || el.webkitRequestFullscreen
      || el.webkitEnterFullscreen
      || el.msRequestFullscreen;
    if (!requestFs) return false;
    try {
      await requestFs.call(el);
      fullscreenEnteredRef.current = true;
      return true;
    } catch (_) {
      return false;
    }
  }, []);

  const lockOrientation = useCallback(async (target) => {
    if (!orientationLockSupported()) return false;
    const entered = await enterFullscreen();
    if (!entered) return false;
    try {
      await window.screen.orientation.lock(target);
      return true;
    } catch (_) {
      return false;
    }
  }, [enterFullscreen]);

  const toggleOrientation = useCallback(async () => {
    const next = orientation === "landscape" ? "portrait" : "landscape";
    const ok = await lockOrientation(next);
    if (ok) setOrientation(next);
  }, [orientation, lockOrientation]);

  useEffect(() => {
    if (!isOpen) return;

    const mobile = window.matchMedia("(max-width: 768px)").matches;
    setIsMobile(mobile);
    setOrientation("landscape");

    const prevOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";

    if (mobile) {
      lockOrientation("landscape");
    }

    const handleKey = (e) => { if (e.key === "Escape") onClose(); };
    window.addEventListener("keydown", handleKey);

    const handleOrientationChange = () => {
      if (window.screen && window.screen.orientation) {
        const type = window.screen.orientation.type;
        if (type && type.startsWith("portrait")) setOrientation("portrait");
        else if (type && type.startsWith("landscape")) setOrientation("landscape");
      }
    };
    if (window.screen && window.screen.orientation) {
      window.screen.orientation.addEventListener("change", handleOrientationChange);
    }

    return () => {
      document.body.style.overflow = prevOverflow;
      window.removeEventListener("keydown", handleKey);
      if (window.screen && window.screen.orientation) {
        window.screen.orientation.removeEventListener("change", handleOrientationChange);
        if (window.screen.orientation.unlock) {
          try { window.screen.orientation.unlock(); } catch (_) {}
        }
      }
      if (fullscreenEnteredRef.current && document.fullscreenElement) {
        const exit = document.exitFullscreen || document.webkitExitFullscreen || document.msExitFullscreen;
        if (exit) { try { exit.call(document); } catch (_) {} }
      }
      fullscreenEnteredRef.current = false;
    };
  }, [isOpen, onClose, lockOrientation]);

  if (!isOpen) return null;

  const showRotateButton = isMobile && orientationLockSupported();

  return (
    <div
      ref={containerRef}
      style={{
        position: "fixed", inset: 0, zIndex: 1000,
        background: "rgba(0,0,0,0.92)",
        display: "flex", alignItems: "center", justifyContent: "center",
        padding: isMobile ? 0 : "40px 20px"
      }}
      onClick={onClose}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          position: "absolute", top: 16, right: 16, zIndex: 2,
          display: "flex", gap: 8
        }}
      >
        {showRotateButton && (
          <button
            onClick={toggleOrientation}
            aria-label={orientation === "landscape" ? "縦画面に切り替え" : "横画面に切り替え"}
            style={{
              background: "rgba(255,255,255,0.15)", border: "none", borderRadius: "50%",
              width: 40, height: 40, cursor: "pointer",
              display: "flex", alignItems: "center", justifyContent: "center",
              color: "#fff"
            }}
          >
            {orientation === "landscape" ? (
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <rect x="7" y="2" width="10" height="20" rx="2" ry="2"/>
                <line x1="11" y1="18" x2="13" y2="18"/>
              </svg>
            ) : (
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <rect x="2" y="7" width="20" height="10" rx="2" ry="2"/>
                <line x1="18" y1="11" x2="18" y2="13"/>
              </svg>
            )}
          </button>
        )}
        <button
          onClick={onClose}
          aria-label="閉じる"
          style={{
            background: "rgba(255,255,255,0.15)", border: "none", borderRadius: "50%",
            width: 40, height: 40, cursor: "pointer",
            display: "flex", alignItems: "center", justifyContent: "center",
            color: "#fff"
          }}
        >
          <svg width="22" height="22" viewBox="0 0 20 20" fill="currentColor">
            <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd"/>
          </svg>
        </button>
      </div>

      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          width: "100%",
          maxWidth: isMobile ? "100%" : 1100,
          height: isMobile ? "100%" : "auto",
          display: "flex", flexDirection: "column", justifyContent: "center"
        }}
      >
        <div style={{
          borderRadius: isMobile ? 0 : 12,
          overflow: "hidden",
          boxShadow: isMobile ? "none" : "0 20px 60px rgba(0,0,0,0.5)",
          height: isMobile ? "100%" : "auto",
          display: isMobile ? "flex" : "block",
          flexDirection: "column"
        }}>
          <VideoPlayer
            preAdUrl={preAdUrl}
            contentUrl={contentUrl}
            postAdUrl={postAdUrl}
            onMainPhaseStart={onMainPhaseStart}
            onComplete={onClose}
            fullHeight={isMobile}
          />
        </div>
      </div>
    </div>
  );
};

const SlideImage = ({ src, onLoaded }) => {
  const [loaded, setLoaded] = useState(false);
  return (
    <div style={{ position: "relative", minHeight: 120 }}>
      {!loaded && (
        <div style={{
          display: "flex", alignItems: "center", justifyContent: "center",
          height: 200, background: "#fafaf9"
        }}>
          <div style={{
            width: 24, height: 24, border: "3px solid #e7e5e4",
            borderTopColor: "#488479", borderRadius: "50%",
            animation: "spin 0.8s linear infinite"
          }} />
          <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
        </div>
      )}
      <img
        src={src}
        onLoad={() => { setLoaded(true); onLoaded && onLoaded(); }}
        style={{
          width: "100%", display: loaded ? "block" : "none"
        }}
      />
    </div>
  );
};

const PDFCarousel = ({ images }) => {
  const [current, setCurrent] = useState(0);
  const [offsetX, setOffsetX] = useState(0);
  const [settling, setSettling] = useState(false);
  const touchStart = useRef(null);
  const containerRef = useRef(null);
  const total = images.length;

  const goTo = useCallback((idx) => {
    setCurrent((idx + total) % total);
  }, [total]);

  const handleTouchStart = (e) => {
    if (settling) return;
    touchStart.current = { x: e.touches[0].clientX, time: Date.now() };
    setOffsetX(0);
  };

  const handleTouchMove = (e) => {
    if (!touchStart.current) return;
    setOffsetX(e.touches[0].clientX - touchStart.current.x);
  };

  const handleTouchEnd = () => {
    if (!touchStart.current) return;
    const elapsed = Date.now() - touchStart.current.time;
    const dx = offsetX;
    const w = containerRef.current ? containerRef.current.offsetWidth : 400;
    const threshold = Math.abs(dx) > w * 0.2 || (Math.abs(dx) > 20 && elapsed < 300);

    if (threshold && total > 1) {
      setSettling(true);
      setOffsetX(dx < 0 ? -w : w);
      setTimeout(() => {
        setCurrent(prev => (dx < 0 ? (prev + 1 + total) % total : (prev - 1 + total) % total));
        setOffsetX(0);
        setSettling(false);
      }, 300);
    } else {
      setSettling(true);
      setOffsetX(0);
      setTimeout(() => setSettling(false), 300);
    }
    touchStart.current = null;
  };

  const handleArrow = (dir) => {
    if (settling) return;
    const w = containerRef.current ? containerRef.current.offsetWidth : 400;
    setSettling(true);
    setOffsetX(dir < 0 ? -w : w);
    setTimeout(() => {
      setCurrent(prev => (prev - dir + total) % total);
      setOffsetX(0);
      setSettling(false);
    }, 300);
  };

  if (total === 0) return null;

  const prevIdx = (current - 1 + total) % total;
  const nextIdx = (current + 1) % total;

  return (
    <div>
      <div style={{ position: "relative" }}>
        <div
          ref={containerRef}
          style={{ overflow: "hidden", touchAction: "pan-y" }}
          onTouchStart={handleTouchStart}
          onTouchMove={handleTouchMove}
          onTouchEnd={handleTouchEnd}
        >
          <div style={{
            display: "flex", width: "300%",
            transform: `translateX(calc(-33.333% + ${offsetX}px))`,
            transition: settling ? "transform 0.3s ease" : "none"
          }}>
            <div style={{ width: "33.333%", flexShrink: 0 }}>
              {total > 1 && <img src={images[prevIdx].url} style={{ width: "100%", display: "block" }} />}
            </div>
            <div style={{ width: "33.333%", flexShrink: 0 }}>
              <SlideImage src={images[current].url} />
            </div>
            <div style={{ width: "33.333%", flexShrink: 0 }}>
              {total > 1 && <img src={images[nextIdx].url} style={{ width: "100%", display: "block" }} />}
            </div>
          </div>
        </div>

        {total > 1 && (
          <>
            <button
              onClick={() => handleArrow(1)}
              style={{
                position: "absolute", left: -12, top: "50%", transform: "translateY(-50%)", zIndex: 2,
                background: "#488479", border: "none",
                width: 34, height: 34, borderRadius: "50%", cursor: "pointer",
                display: "flex", alignItems: "center", justifyContent: "center",
                boxShadow: "0 2px 8px rgba(72,132,121,0.4)", padding: 0
              }}
            ><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"/></svg></button>
            <button
              onClick={() => handleArrow(-1)}
              style={{
                position: "absolute", right: -12, top: "50%", transform: "translateY(-50%)", zIndex: 2,
                background: "#488479", border: "none",
                width: 34, height: 34, borderRadius: "50%", cursor: "pointer",
                display: "flex", alignItems: "center", justifyContent: "center",
                boxShadow: "0 2px 8px rgba(72,132,121,0.4)", padding: 0
              }}
            ><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="9 6 15 12 9 18"/></svg></button>
          </>
        )}
      </div>

      {total > 1 && (
        <div style={{ display: "flex", justifyContent: "center", alignItems: "center", gap: 8, padding: "12px 0" }}>
          <div style={{ display: "flex", gap: 6, flex: 1, justifyContent: "center" }}>
            {images.map((_, i) => (
              <button
                key={i}
                onClick={() => { if (!settling) setCurrent(i); }}
                style={{
                  width: i === current ? 20 : 8, height: 8,
                  borderRadius: 4, border: "none", padding: 0, cursor: "pointer",
                  background: i === current ? "#488479" : "#d6d3d1",
                  transition: "all 0.3s"
                }}
              />
            ))}
          </div>
          <span style={{ color: "#a8a29e", fontSize: 12, flexShrink: 0 }}>{current + 1} / {total}</span>
        </div>
      )}
    </div>
  );
};

const UpsellSection = ({ content, upsellConsultationUrl, monitorApplyUrl, onTrackActivity }) => {
  const [consultationStatus, setConsultationStatus] = useState(content.consultation_status);
  const [monitorApplied, setMonitorApplied] = useState(content.has_monitor_applied);
  const [isLoading, setIsLoading] = useState(false);

  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

  const safeJsonFetch = async (url) => {
    try {
      const res = await fetch(url, {
        method: "POST",
        headers: { "X-CSRF-Token": csrfToken, "Accept": "application/json" }
      });
      if (!res.ok) {
        console.error("[EventContent] Request failed:", url, res.status);
        return null;
      }
      return await res.json();
    } catch (err) {
      console.error("[EventContent] Request error:", url, err);
      return null;
    }
  };

  const handleConsultation = async () => {
    if (consultationStatus || isLoading) return;
    setIsLoading(true);
    onTrackActivity && onTrackActivity("upsell_click");
    const data = await safeJsonFetch(upsellConsultationUrl);
    if (data && data.success) setConsultationStatus(data.status);
    setIsLoading(false);
  };

  const handleMonitorApply = async () => {
    if (monitorApplied || isLoading) return;
    setIsLoading(true);
    const data = await safeJsonFetch(monitorApplyUrl);
    if (data && data.success) {
      setMonitorApplied(true);
      if (data.form_url) window.open(data.form_url, "_blank");
    }
    setIsLoading(false);
  };

  return (
    <>
      {content.upsell_booking_enabled && (
        <div style={{ background: "#fff", padding: "20px", marginBottom: 16, borderBottom: "1px solid #e7e5e4" }}>
          <h4 style={{ fontWeight: 700, fontSize: 15, margin: "0 0 14px", color: "#1c1917" }}>無料相談予約</h4>
          {consultationStatus ? (
            <div style={{ textAlign: "center", color: "#44403c", padding: 12, fontWeight: 700, fontSize: 14 }}>
              {consultationStatus === "waitlist" ? "キャンセル待ちを承りました" : "予約済みです"}
            </div>
          ) : (
            <button
              onClick={handleConsultation}
              disabled={isLoading}
              style={{ width: "100%", padding: "12px", background: "#e6a21f", color: "#fff", border: "none", borderRadius: 8, fontSize: 14, fontWeight: 700, cursor: "pointer" }}
            >
              {isLoading ? "処理中..." : "無料相談を予約する"}
            </button>
          )}
        </div>
      )}

      {content.monitor_enabled && (
        <div style={{ background: "#fff", padding: "20px", marginBottom: 16, borderBottom: "1px solid #e7e5e4" }}>
          <h4 style={{ fontWeight: 700, fontSize: 15, margin: "0 0 8px", color: "#1c1917" }}>モニター応募</h4>
          {content.monitor_name && <p style={{ fontSize: 13, color: "#78716c", marginBottom: 4 }}>サービス: {content.monitor_name}</p>}
          {content.monitor_price !== null && <p style={{ fontSize: 13, color: "#44403c", marginBottom: 10, fontWeight: 600 }}>モニター金額: {content.monitor_price.toLocaleString()}円</p>}
          {monitorApplied ? (
            <div style={{ textAlign: "center", color: "#44403c", padding: 12, fontWeight: 700, fontSize: 14 }}>応募済みです</div>
          ) : (
            <button
              onClick={handleMonitorApply}
              disabled={isLoading}
              style={{ width: "100%", padding: "12px", background: "#e6a21f", color: "#fff", border: "none", borderRadius: 8, fontSize: 14, fontWeight: 700, cursor: "pointer" }}
            >
              {isLoading ? "処理中..." : "モニターに応募する"}
            </button>
          )}
        </div>
      )}
    </>
  );
};

// セミナー講演の詳細ページ最下部に表示する「あなたへおすすめのセミナー講演」スライダー。
// TOPページの RecommendationCarousel に比べ、各カードを小さくして横スクロール（スナップ付き）で複数並べるレイアウト。
// データはサーバー側で参加者プロフィールに合わせて並び替え済み（exhibitor_roles マッチを優先）のものを受け取る。
const RecommendedSeminarCarousel = ({ contents, eventLogoUrl }) => {
  if (!contents || contents.length === 0) return null;

  return (
    <div style={{ background: "#488479", padding: "20px 12px", marginTop: 32 }}>
      <div style={{ maxWidth: 720, margin: "0 auto" }}>
        <h2 style={{
          fontSize: 14, fontWeight: 800, marginTop: 0, marginBottom: 12, color: "#FAEACB",
          display: "flex", alignItems: "center", gap: 6
        }}>
          <span aria-hidden="true">🎯</span>
          あなたへおすすめのセミナー講演
        </h2>
        <div
          style={{
            display: "flex",
            gap: 10,
            overflowX: "auto",
            paddingBottom: 6,
            scrollSnapType: "x mandatory",
            WebkitOverflowScrolling: "touch"
          }}
        >
          {contents.map((c) => {
            const isDraft = c.status === "unpublished";
            return (
              <a
                key={c.id}
                href={c.url}
                style={{
                  flex: "0 0 auto",
                  width: 150,
                  textDecoration: "none",
                  color: "inherit",
                  scrollSnapAlign: "start"
                }}
              >
                <div style={{
                  background: "#fff", overflow: "hidden",
                  border: "1px solid rgba(0,0,0,0.06)",
                  display: "flex", flexDirection: "column", height: "100%"
                }}>
                  <div style={{ position: "relative", width: "100%", paddingBottom: "56.25%", flexShrink: 0, background: c.thumbnail_url ? "#f5f5f4" : "rgb(70, 67, 66)" }}>
                    {c.thumbnail_url ? (
                      <img src={c.thumbnail_url} style={{ position: "absolute", top: 0, left: 0, width: "100%", height: "100%", objectFit: "cover", display: "block" }} />
                    ) : (
                      <div style={{ position: "absolute", top: 0, left: 0, width: "100%", height: "100%", display: "flex", alignItems: "center", justifyContent: "center" }}>
                        {eventLogoUrl
                          ? <img src={eventLogoUrl} style={{ maxWidth: "70%", maxHeight: "70%", objectFit: "contain" }} />
                          : <span style={{ fontSize: 30 }}>🎬</span>}
                      </div>
                    )}
                  </div>
                  <div style={{ padding: "8px 10px", display: "flex", flexDirection: "column", flex: 1, minWidth: 0 }}>
                    <div style={{ display: "flex", gap: 4, marginBottom: 4, flexWrap: "wrap" }}>
                      <span style={{
                        fontSize: 9, padding: "1px 6px", borderRadius: 8, fontWeight: 700, color: "#fff",
                        background: "#B95526", lineHeight: 1.4
                      }}>セミナー講演</span>
                      {isDraft && (
                        <span style={{
                          fontSize: 9, padding: "1px 6px", borderRadius: 8, fontWeight: 700,
                          background: "#fef3c7", color: "#92400e", border: "1px solid #fcd34d", lineHeight: 1.4
                        }}>下書き</span>
                      )}
                    </div>
                    <div style={{
                      fontSize: 12, fontWeight: 700, lineHeight: 1.4, color: "#1c1917",
                      display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden",
                      flex: 1
                    }}>{c.title}</div>
                    {c.exhibitor_name && (
                      <div style={{
                        fontSize: 10, color: "#78716c", marginTop: 4,
                        whiteSpace: "pre-line",
                        display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden"
                      }}>{c.exhibitor_name}</div>
                    )}
                  </div>
                </div>
              </a>
            );
          })}
        </div>
      </div>
    </div>
  );
};

const EventContentShow = ({ props }) => {
  const {
    event_content, event_slug, event_title,
    start_usage_url, upsell_consultation_url, monitor_apply_url,
    track_activity_url, back_url, line_login_url, add_friend_url,
    current_event_line_user_id, event_ended, event_logo_image_url
  } = props;

  const [hasStarted, setHasStarted] = useState(event_content.has_started_usage);
  const [isStarting, setIsStarting] = useState(false);
  const [shareOpen, setShareOpen] = useState(false);
  const [isVideoModalOpen, setIsVideoModalOpen] = useState(false);

  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  const isParticipant = event_content.is_participant;
  const isLoggedIn = event_content.is_logged_in;
  const canStart = event_content.started && !event_content.ended && !event_content.capacity_full;

  const trackActivity = (activityType, metadata) => {
    if (!track_activity_url || !isLoggedIn) return;
    const body = { activity_type: activityType };
    if (metadata) body.metadata = metadata;
    fetch(track_activity_url, {
      method: "POST",
      headers: { "X-CSRF-Token": csrfToken, "Content-Type": "application/json" },
      body: JSON.stringify(body)
    }).catch(() => {});
  };

  const openVideoModalIfSeminar = () => {
    if (event_content.content_type === "seminar") setIsVideoModalOpen(true);
  };

  const handleStartUsage = async () => {
    if (isStarting) return;
    if (hasStarted) {
      openVideoModalIfSeminar();
      return;
    }
    setIsStarting(true);
    try {
      const res = await fetch(start_usage_url, {
        method: "POST",
        headers: { "X-CSRF-Token": csrfToken, "Accept": "application/json" }
      });
      if (res.ok) {
        const data = await res.json();
        if (data.success) {
          setHasStarted(true);
          if (event_content.content_type === "seminar") trackActivity("seminar_view");
          openVideoModalIfSeminar();
        }
      } else {
        console.error("[EventContent] start_usage failed:", res.status);
        setHasStarted(true);
        if (event_content.content_type === "seminar") trackActivity("seminar_view");
        openVideoModalIfSeminar();
      }
    } catch (err) {
      console.error("[EventContent] start_usage error:", err);
      setHasStarted(true);
      if (event_content.content_type === "seminar") trackActivity("seminar_view");
      openVideoModalIfSeminar();
    }
    setIsStarting(false);
  };

  const ctaLabel = event_content.content_type === "booth" ? "資料をダウンロード" : "セミナー講演を視聴";
  const typeColor = "#60938a";

  // ヘッダーサブナビ用のリンクをイベントTOPから組み立てる。
  // back_url 例: "/expo2026" → セミナー: "/expo2026?tab=seminar#contents", スタンプラリー: "/expo2026#stamp-rally"
  const subNavLinks = [
    { label: "セミナー講演", href: `${back_url}?tab=seminar#contents` },
    { label: "展示ブース", href: `${back_url}?tab=booth#contents` },
    { label: "スタンプラリー", href: `${back_url}#stamp-rally` }
  ];

  return (
    <div style={{ minHeight: "100vh", background: "#fafaf9" }}>
      {/* Header — 背景はイベント TOP のヒーロー(画像なし時)と同じ #464342 で統一 */}
      <div style={{ background: "#464342", color: "#fff", padding: "10px 16px 6px", position: "sticky", top: 0, zIndex: 20 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8, maxHeight: 28 }}>
          <a href={back_url} style={{ color: "#fff", textDecoration: "none", flexShrink: 0, display: "flex", alignItems: "center", justifyContent: "center", width: 28, height: 36, marginLeft: -4 }}>
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"/></svg>
          </a>
          {event_logo_image_url && (
            <img
              src={event_logo_image_url}
              alt={event_title || ""}
              style={{ height: 28, width: "auto", maxHeight: "100%", display: "block", objectFit: "contain" }}
            />
          )}
        </div>

        {/* サブナビ（イベントTOPの該当セクションへの導線）— オーバル枠リンクで横並び */}
        <nav style={{
          display: "flex", justifyContent: "center", alignItems: "center",
          gap: 6, paddingTop: 8
        }}>
          {subNavLinks.map((link) => (
            <a
              key={link.label}
              href={link.href}
              style={{
                color: "#fff",
                textDecoration: "none",
                fontSize: 11,
                fontWeight: 600,
                letterSpacing: "0.02em",
                whiteSpace: "nowrap",
                lineHeight: 1,
                padding: "6px 14px",
                border: "1px solid rgba(255,255,255,0.55)",
                borderRadius: 999,
                background: "rgba(255,255,255,0.06)"
              }}
            >
              {link.label}
            </a>
          ))}
        </nav>
      </div>

      <div style={{ maxWidth: 720, margin: "0 auto", padding: "20px 16px" }}>
        {/* Draft (unpublished) preview banner — only viewers with preview privilege reach this page for drafts. */}
        {event_content.status === "unpublished" && (
          <div style={{
            background: "#fef3c7", border: "1px solid #fcd34d", color: "#92400e",
            borderRadius: 8, padding: "10px 14px", fontSize: 13, fontWeight: 700,
            marginBottom: 16, display: "flex", alignItems: "center", gap: 8
          }}>
            <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fillRule="evenodd" d="M8.485 2.495a1.75 1.75 0 013.03 0l6.28 10.875A1.75 1.75 0 0116.28 16H3.72a1.75 1.75 0 01-1.515-2.63L8.485 2.495zM10 6a1 1 0 011 1v3a1 1 0 11-2 0V7a1 1 0 011-1zm-1 7a1 1 0 112 0 1 1 0 01-2 0z" clipRule="evenodd"/>
            </svg>
            このコンテンツは下書き(非公開)です。プレビュー権限のあるユーザーのみ閲覧できます。
          </div>
        )}

        {/* Thumbnail / Content area
            セミナー / 展示ブース ともに hasStarted の状態で構成を変えず、常にプレーンなサムネ表示。
            （何度でも詳細ページに戻ってきても、レイアウトが変わって混乱しないようにするため） */}
        <div style={{ overflow: "hidden", marginBottom: 0 }}>
          {event_content.thumbnail_url ? (
            <img src={event_content.thumbnail_url} style={{ width: "100%", maxHeight: 320, objectFit: "cover", display: "block" }} />
          ) : (
            <div style={{ height: 180, background: typeColor, display: "flex", alignItems: "center", justifyContent: "center" }}>
              <span style={{ fontSize: 56 }}>{event_content.content_type === "seminar" ? "🎬" : "📄"}</span>
            </div>
          )}
        </div>

        {/* Title + Share (below thumbnail) */}
        <div style={{ textAlign: "center", padding: "20px 0 16px" }}>
          {event_content.status === "unpublished" && (
            <div style={{ marginBottom: 8 }}>
              <span style={{
                display: "inline-block",
                background: "#fef3c7", color: "#92400e", border: "1px solid #fcd34d",
                fontSize: 11, padding: "3px 10px", borderRadius: 12, fontWeight: 700
              }}>
                下書き(プレビュー表示)
              </span>
            </div>
          )}
          <h2 style={{ fontSize: 20, fontWeight: 800, color: "#1c1917", lineHeight: 1.4, margin: "0 0 14px" }}>
            {event_content.title}
          </h2>
          <button
            onClick={() => setShareOpen(true)}
            style={{
              display: "inline-flex", alignItems: "center", gap: 6,
              padding: "8px 18px", border: "1px solid #d6d3d1", borderRadius: 20,
              background: "#fff", cursor: "pointer", fontSize: 13, fontWeight: 600, color: "#44403c"
            }}
          >
            <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor"><path d="M15 8a3 3 0 10-2.977-2.63l-4.94 2.47a3 3 0 100 4.319l4.94 2.47a3 3 0 10.895-1.789l-4.94-2.47a3.027 3.027 0 000-.74l4.94-2.47C13.456 7.68 14.19 8 15 8z"/></svg>
            シェア
          </button>
        </div>

        {/* Preview slides for booth participants — 利用開始の有無に関わらず常に表示。
            （構成が変わるとユーザーが戻ってきたときに混乱するため） */}
        {isParticipant && event_content.content_type === "booth" && (event_content.slide_images || []).length > 0 && (
          <div style={{ marginBottom: 20 }}>
            <h3 style={{ fontSize: 14, fontWeight: 700, color: "#374151", marginBottom: 10 }}>プレビュー</h3>
            <PDFCarousel
              images={(event_content.slide_images || []).slice(0, 3)}
              onlineServiceUrl={null}
            />
            {(event_content.slide_images || []).length > 3 && (
              <p style={{ textAlign: "center", fontSize: 12, color: "#9ca3af", marginTop: 8 }}>
                全 {event_content.slide_images.length} ページ
              </p>
            )}
          </div>
        )}

        {/* Status messages
            - コンテンツの公開期間が終了した場合に「配信終了しました」を表示。
            - イベント自体が終了している場合は、コンテンツが公開期間中でも強制的に同表示にし、
              以降のCTAを全て隠す（イベントが終わっている以上、利用や視聴・DLは出来ないため）。 */}
        {(event_content.ended || event_ended) && (
          <div style={{ background: "#fafaf9", border: "1px solid #e7e5e4", color: "#57534e", padding: "12px 16px", textAlign: "center", marginBottom: 16, fontWeight: 700, fontSize: 14 }}>
            配信終了しました
          </div>
        )}

        {/* 公開開始前: 「サービス開始前」テキストの代わりに配信開始日時を太字・黒文字で表示
            ※ イベント自体が終了済の場合は表示しない（未来日時を出しても意味がないため）。 */}
        {!event_content.started && !event_content.ended && !event_ended && (() => {
          const formatted = formatJaDateTimeShort(event_content.start_at);
          if (!formatted) return null;
          return (
            <div style={{ color: "#1c1917", padding: "12px 16px", marginBottom: 16, fontSize: 18, fontWeight: 700, display: "flex", alignItems: "center", justifyContent: "center", gap: 8 }}>
              <svg width="22" height="22" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true" style={{ flexShrink: 0 }}>
                <path fillRule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clipRule="evenodd"/>
              </svg>
              <span>配信開始：{formatted}〜</span>
            </div>
          );
        })()}

        {/* Primary CTA: 展示ブース
            - hasStarted の有無に関わらず常に表示し、押下時は外部のDL先へ何度でも遷移できる。
            - 公開開始前 / 定員満了 / コンテンツ終了 のときは disabled な見た目だけ表示し、href を出さない。
            - イベント自体が終了している場合はブロック自体を非表示。 */}
        {isParticipant && !event_content.ended && !event_ended && event_content.content_type === "booth" && (() => {
          const downloadUrl = event_content.online_service_registration_url;
          const isEnabled = canStart || hasStarted;
          const baseStyle = {
            width: "100%", padding: "14px",
            background: isEnabled ? typeColor : "#d6d3d1",
            color: "#fff", border: "none",
            borderRadius: 8, fontSize: 16, fontWeight: 700,
            cursor: isEnabled ? "pointer" : "not-allowed",
            boxShadow: isEnabled ? `0 4px 14px ${typeColor}66` : "none",
            opacity: isEnabled ? 1 : 0.85,
            display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
            textDecoration: "none", boxSizing: "border-box"
          };
          const icon = (
            <svg width="18" height="18" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fillRule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clipRule="evenodd"/>
            </svg>
          );
          const handleBoothClick = () => {
            if (downloadUrl) {
              trackActivity("material_download", { url: downloadUrl });
            }
            if (start_usage_url) {
              fetch(start_usage_url, {
                method: "POST",
                headers: { "X-CSRF-Token": csrfToken, "Accept": "application/json" }
              }).then(() => setHasStarted(true)).catch(() => {});
            }
          };
          return (
            <div style={{ marginBottom: 20 }}>
              {isEnabled && downloadUrl ? (
                <a
                  href={downloadUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  onClick={handleBoothClick}
                  style={baseStyle}
                >
                  {icon}
                  {ctaLabel}
                </a>
              ) : (
                <button
                  type="button"
                  disabled={!isEnabled}
                  onClick={isEnabled ? handleBoothClick : undefined}
                  style={baseStyle}
                >
                  {icon}
                  {ctaLabel}
                </button>
              )}
            </div>
          );
        })()}

        {/* Primary CTA: セミナー講演
            - hasStarted の有無に関わらず常に表示する（展示ブースと同じ振る舞い）。
            - 公開開始前 / コンテンツ終了 / 定員フル のときは disabled な見た目だけ表示。
            - canStart のときのみ押下可能で、handleStartUsage が初回 / 再生 を判定する。
            - イベント自体が終了している場合はブロック自体を非表示。 */}
        {isParticipant && !event_content.ended && !event_ended && event_content.content_type === "seminar" && (
          <div style={{ marginBottom: 20 }}>
            <button
              onClick={canStart ? handleStartUsage : undefined}
              disabled={!canStart || isStarting}
              style={{
                width: "100%", padding: "14px",
                background: canStart ? typeColor : "#d6d3d1",
                color: "#fff", border: "none",
                borderRadius: 8, fontSize: 16, fontWeight: 700,
                cursor: canStart ? "pointer" : "not-allowed",
                boxShadow: canStart ? `0 4px 14px ${typeColor}66` : "none",
                opacity: canStart ? 1 : 0.85,
                display: "flex", alignItems: "center", justifyContent: "center", gap: 8
              }}
            >
              <svg width="18" height="18" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                <path d="M6.3 2.841A1.5 1.5 0 004 4.11v11.78a1.5 1.5 0 002.3 1.269l9.344-5.89a1.5 1.5 0 000-2.538L6.3 2.84z"/>
              </svg>
              {isStarting ? "..." : ctaLabel}
            </button>
            {/* 資料DLの直リンクは廃止。資料配布や別コンテンツ誘導は「関連コンテンツ」セクションへ統一 */}
          </div>
        )}

        {/* LINE login CTA for non-participants（イベント終了後は出さない）
            参加登録前のユーザーには関連コンテンツより前（シェアボタン直下）に出して、
            まず参加登録／ログインに誘導する。 */}
        {!isParticipant && line_login_url && !event_ended && (
          <div style={{ background: "#fafaf9", border: "1px solid #e7e5e4", padding: "24px 20px", marginBottom: 20, textAlign: "center" }}>
            <EventLineLoginLink loginUrl={line_login_url} btnText="参加登録／ログイン" />
          </div>
        )}

        {/* 関連コンテンツ
            - CTA の下に余白を空けて、紐付けたコンテンツへの導線を表示する
            - イベント開催期間 / コンテンツ公開期間に関わらず常に表示
            - ボタンは #488479 のセカンダリスタイル */}
        {(event_content.related_contents || []).length > 0 && (
          <div style={{ marginTop: 48, marginBottom: 20 }}>
            <h3 style={{
              fontSize: 14, fontWeight: 700, color: "#374151",
              margin: "0 0 12px", textAlign: "center"
            }}>
              関連コンテンツ
            </h3>
            <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
              {event_content.related_contents.map((rc) => (
                <a
                  key={rc.id}
                  href={rc.url}
                  style={{
                    display: "flex", alignItems: "center", justifyContent: "center",
                    gap: 8,
                    padding: "12px 18px",
                    background: "#fff",
                    color: "#488479",
                    border: "1.5px solid #488479",
                    borderRadius: 8,
                    textDecoration: "none",
                    fontWeight: 700,
                    fontSize: 14,
                    lineHeight: 1.4,
                    textAlign: "center"
                  }}
                >
                  {rc.title}
                  <svg width="14" height="14" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true" style={{ flexShrink: 0 }}>
                    <path fillRule="evenodd" d="M7.05 4.05a.75.75 0 011.06 0l5.366 5.367a.75.75 0 010 1.061L8.11 15.95a.75.75 0 11-1.06-1.06L11.94 10 7.05 5.11a.75.75 0 010-1.06z" clipRule="evenodd"/>
                  </svg>
                </a>
              ))}
            </div>
          </div>
        )}

        {/* Description */}
        {event_content.description && (
          <div style={{ background: "#fff", padding: "20px", marginBottom: 16, borderBottom: "1px solid #e7e5e4" }}>
            <p style={{ color: "#57534e", lineHeight: 1.8, whiteSpace: "pre-wrap", fontSize: 14 }}>{event_content.description}</p>
          </div>
        )}

        {/* Upsell（無料相談予約 / モニター応募）
            参加登録済かつイベント未終了であれば、コンテンツ未利用 (hasStarted=false) でも常に表示する。
            未参加ユーザはここでは出さない (上の LINE login CTA で誘導)。 */}
        {isParticipant && !event_ended && (event_content.upsell_booking_enabled || event_content.monitor_enabled) && (
          <UpsellSection
            content={event_content}
            upsellConsultationUrl={upsell_consultation_url}
            monitorApplyUrl={monitor_apply_url}
            onTrackActivity={trackActivity}
          />
        )}

        {/* 出演者情報 / 出展者情報 はコンテンツ詳細の最下部に配置する。 */}
        {(event_content.speakers || []).length > 0 && (
          <div style={{ background: "#fff", padding: "20px", marginBottom: 16, borderBottom: "1px solid #e7e5e4" }}>
            <h3 style={{ fontWeight: 700, fontSize: 15, marginBottom: 14, color: "#1c1917" }}>出演者情報</h3>
            <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
              {event_content.speakers.map((speaker, idx) => (
                <div key={speaker.id || idx} style={{ display: "flex", gap: 14, alignItems: "flex-start" }}>
                  {speaker.profile_image_url ? (
                    <img src={speaker.profile_image_url} style={{ width: 72, height: 72, borderRadius: "50%", objectFit: "cover", flexShrink: 0, border: "3px solid #f5f5f4" }} />
                  ) : (
                    <div style={{ width: 72, height: 72, borderRadius: "50%", background: "#e7e5e4", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, fontSize: 28, color: "#a8a29e" }}>👤</div>
                  )}
                  <div>
                    {speaker.position_title && (
                      <div style={{ fontSize: 12, color: "#a8a29e", marginBottom: 2 }}>{speaker.position_title}</div>
                    )}
                    <div style={{ fontWeight: 700, fontSize: 16, color: "#1c1917", marginBottom: 6 }}>{speaker.name}</div>
                    {speaker.introduction && (
                      <p style={{ fontSize: 13, color: "#78716c", lineHeight: 1.7, whiteSpace: "pre-wrap" }}>{linkifyText(speaker.introduction)}</p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {(event_content.speakers || []).length === 0 && event_content.exhibitor_staff && (
          <div style={{ background: "#fff", padding: "20px", marginBottom: 16, borderBottom: "1px solid #e7e5e4" }}>
            <h3 style={{ fontWeight: 700, fontSize: 15, marginBottom: 14, color: "#1c1917" }}>出展者情報</h3>
            <div style={{ display: "flex", gap: 14, alignItems: "flex-start" }}>
              {event_content.exhibitor_staff.picture_url && (
                event_content.content_type === "booth" && !event_content.exhibitor_staff.position ? (
                  <img src={event_content.exhibitor_staff.picture_url} style={{ width: 72, height: 72, objectFit: "contain", flexShrink: 0, background: "#fafaf9", padding: 4 }} />
                ) : (
                  <img src={event_content.exhibitor_staff.picture_url} style={{ width: 72, height: 72, borderRadius: "50%", objectFit: "cover", flexShrink: 0, border: "3px solid #f5f5f4" }} />
                )
              )}
              <div>
                {event_content.exhibitor_staff.position && (
                  <div style={{ fontSize: 12, color: "#a8a29e", marginBottom: 2 }}>{event_content.exhibitor_staff.position}</div>
                )}
                <div style={{ fontWeight: 700, fontSize: 16, color: "#1c1917", marginBottom: 6, whiteSpace: "pre-line" }}>{event_content.exhibitor_staff.name}</div>
                {event_content.exhibitor_staff.introduction && (
                  <p style={{ fontSize: 13, color: "#78716c", lineHeight: 1.7, whiteSpace: "pre-wrap" }}>{linkifyText(event_content.exhibitor_staff.introduction)}</p>
                )}
              </div>
            </div>
          </div>
        )}
      </div>

      {/* セミナー講演詳細ページ最下部の「あなたへおすすめのセミナー講演」スライダー。
          中央 720px のコンテンツカラムの外に置いて、TOPページのおすすめカルーセルと同じく全幅で表示する。 */}
      {event_content.content_type === "seminar" && (
        <RecommendedSeminarCarousel
          contents={event_content.recommended_seminar_contents || []}
          eventLogoUrl={event_logo_image_url}
        />
      )}

      <ShareModal
        isOpen={shareOpen}
        onClose={() => setShareOpen(false)}
        title="このコンテンツをシェアする"
        shareTitle={event_content.title}
        thumbnailUrl={event_content.thumbnail_url || null}
        shareUrl={(() => {
          if (typeof window === "undefined") return "";
          try {
            const u = new URL(window.location.href);
            u.searchParams.delete("rs");
            if (current_event_line_user_id) {
              u.searchParams.set("ru", String(current_event_line_user_id));
            } else {
              u.searchParams.delete("ru");
            }
            return u.toString();
          } catch (e) {
            return window.location.href;
          }
        })()}
      />

      {event_content.content_type === "seminar" && (
        <VideoPlayerModal
          isOpen={isVideoModalOpen}
          onClose={() => setIsVideoModalOpen(false)}
          preAdUrl={event_content.pre_ad_video_url}
          contentUrl={event_content.video_url || event_content.online_service_registration_url}
          postAdUrl={event_content.post_ad_video_url}
          onMainPhaseStart={() => trackActivity("seminar_view")}
        />
      )}
    </div>
  );
};

export default EventContentShow;
