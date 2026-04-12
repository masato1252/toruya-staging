"use strict"

import React, { useState, useRef, useEffect, useCallback } from "react";

const getEmbedUrl = (url) => {
  if (!url) return null;
  const ytMatch = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]+)/);
  if (ytMatch) return `https://www.youtube.com/embed/${ytMatch[1]}?autoplay=1&rel=0`;
  const driveMatch = url.match(/\/file\/d\/([a-zA-Z0-9_-]+)/);
  if (driveMatch) return `https://drive.google.com/file/d/${driveMatch[1]}/preview`;
  return url;
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
          background: "#134e4a", color: "#fff", padding: "16px 20px",
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

const VideoPlayer = ({ preAdUrl, contentUrl, postAdUrl, onComplete, onMainPhaseStart }) => {
  const [phase, setPhase] = useState(preAdUrl ? "pre_ad" : "main");
  const [iframeKey, setIframeKey] = useState(0);
  const mainFired = useRef(!preAdUrl);

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

  const phaseLabel = phase === "pre_ad" ? "広告" : phase === "main" ? "セミナー本編" : "広告";

  return (
    <div style={{ background: "#000", overflow: "hidden" }}>
      <div style={{ padding: "8px 14px", background: "rgba(255,255,255,0.08)", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <span style={{ color: "#fff", fontSize: 12, fontWeight: 600 }}>{phaseLabel}</span>
        <button onClick={nextPhase} style={{ background: "rgba(255,255,255,0.15)", color: "#fff", border: "none", borderRadius: 6, padding: "5px 14px", cursor: "pointer", fontSize: 12, fontWeight: 600 }}>
          {phase === "post_ad" ? "完了" : "次へ ▶"}
        </button>
      </div>
      <div style={{ position: "relative", paddingBottom: "56.25%" }}>
        <iframe
          key={iframeKey}
          src={getEmbedUrl(currentUrl)}
          frameBorder="0"
          allowFullScreen
          allow="autoplay; encrypted-media"
          style={{ position: "absolute", top: 0, left: 0, width: "100%", height: "100%" }}
        />
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
            borderTopColor: "#0d9488", borderRadius: "50%",
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
                background: "#0d9488", border: "none",
                width: 34, height: 34, borderRadius: "50%", cursor: "pointer",
                display: "flex", alignItems: "center", justifyContent: "center",
                boxShadow: "0 2px 8px rgba(13,148,136,0.4)", padding: 0
              }}
            ><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"/></svg></button>
            <button
              onClick={() => handleArrow(-1)}
              style={{
                position: "absolute", right: -12, top: "50%", transform: "translateY(-50%)", zIndex: 2,
                background: "#0d9488", border: "none",
                width: 34, height: 34, borderRadius: "50%", cursor: "pointer",
                display: "flex", alignItems: "center", justifyContent: "center",
                boxShadow: "0 2px 8px rgba(13,148,136,0.4)", padding: 0
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
                  background: i === current ? "#0d9488" : "#d6d3d1",
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

  const handleConsultation = async () => {
    if (consultationStatus || isLoading) return;
    setIsLoading(true);
    onTrackActivity && onTrackActivity("upsell_click");
    const res = await fetch(upsellConsultationUrl, { method: "POST", headers: { "X-CSRF-Token": csrfToken } });
    const data = await res.json();
    if (data.success) setConsultationStatus(data.status);
    setIsLoading(false);
  };

  const handleMonitorApply = async () => {
    if (monitorApplied || isLoading) return;
    setIsLoading(true);
    const res = await fetch(monitorApplyUrl, { method: "POST", headers: { "X-CSRF-Token": csrfToken } });
    const data = await res.json();
    if (data.success) {
      setMonitorApplied(true);
      if (data.form_url) window.open(data.form_url, "_blank");
    }
    setIsLoading(false);
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
      {content.upsell_booking_enabled && (
        <div style={{ background: "#fafaf9", border: "1px solid #e7e5e4", padding: "20px" }}>
          <h4 style={{ fontWeight: 700, fontSize: 15, marginBottom: 10, color: "#1c1917" }}>無料相談を予約する</h4>
          {consultationStatus ? (
            <div style={{ textAlign: "center", color: "#44403c", padding: 12, fontWeight: 700, fontSize: 14 }}>
              {consultationStatus === "waitlist" ? "キャンセル待ちを承りました" : "予約済みです"}
            </div>
          ) : (
            <button
              onClick={handleConsultation}
              disabled={isLoading}
              style={{ width: "100%", padding: "12px", background: "#0d9488", color: "#fff", border: "none", borderRadius: 8, fontSize: 14, fontWeight: 700, cursor: "pointer" }}
            >
              {isLoading ? "処理中..." : "無料相談を予約する"}
            </button>
          )}
        </div>
      )}

      {content.monitor_enabled && (
        <div style={{ background: "#fafaf9", border: "1px solid #e7e5e4", padding: "20px" }}>
          <h4 style={{ fontWeight: 700, fontSize: 15, marginBottom: 6, color: "#1c1917" }}>モニターに応募する</h4>
          {content.monitor_name && <p style={{ fontSize: 13, color: "#78716c", marginBottom: 4 }}>サービス: {content.monitor_name}</p>}
          {content.monitor_price !== null && <p style={{ fontSize: 13, color: "#44403c", marginBottom: 10, fontWeight: 600 }}>モニター金額: {content.monitor_price.toLocaleString()}円</p>}
          {monitorApplied ? (
            <div style={{ textAlign: "center", color: "#44403c", padding: 12, fontWeight: 700, fontSize: 14 }}>応募済みです</div>
          ) : (
            <button
              onClick={handleMonitorApply}
              disabled={isLoading}
              style={{ width: "100%", padding: "12px", background: "#334155", color: "#fff", border: "none", borderRadius: 8, fontSize: 14, fontWeight: 700, cursor: "pointer" }}
            >
              {isLoading ? "処理中..." : "モニターに応募する"}
            </button>
          )}
        </div>
      )}
    </div>
  );
};

const EventContentShow = ({ props }) => {
  const {
    event_content, event_slug, event_title,
    start_usage_url, upsell_consultation_url, monitor_apply_url,
    track_activity_url, back_url, line_login_url, add_friend_url
  } = props;

  const [hasStarted, setHasStarted] = useState(event_content.has_started_usage);
  const [isStarting, setIsStarting] = useState(false);
  const [shareOpen, setShareOpen] = useState(false);

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

  const handleStartUsage = async () => {
    if (isStarting || hasStarted) return;
    setIsStarting(true);
    const res = await fetch(start_usage_url, { method: "POST", headers: { "X-CSRF-Token": csrfToken } });
    const data = await res.json();
    if (data.success) {
      setHasStarted(true);
      if (event_content.content_type === "seminar") trackActivity("seminar_view");
    }
    setIsStarting(false);
  };

  const ctaLabel = "詳しく見る";
  const typeColor = event_content.content_type === "seminar" ? "#334155" : "#0d9488";

  return (
    <div style={{ minHeight: "100vh", background: "#fafaf9" }}>
      {/* Header */}
      <div style={{ background: "#0f172a", color: "#fff", padding: "14px 20px", display: "flex", alignItems: "center", gap: 8, position: "sticky", top: 0, zIndex: 20 }}>
        <a href={back_url} style={{ color: "#fff", textDecoration: "none", flexShrink: 0, display: "flex", alignItems: "center", justifyContent: "center", width: 28, height: 36, marginLeft: -4 }}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"/></svg>
        </a>
        <div style={{ minWidth: 0 }}>
          <div style={{ fontSize: 11, opacity: 0.6, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{event_title}</div>
          <h1 style={{ fontSize: 15, fontWeight: 700, margin: 0, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{event_content.title}</h1>
        </div>
      </div>

      <div style={{ maxWidth: 720, margin: "0 auto", padding: "20px 16px" }}>
        {/* Thumbnail / Content area */}
        {hasStarted && event_content.content_type === "seminar" ? (
          <div style={{ marginBottom: 20 }}>
            <VideoPlayer
              preAdUrl={event_content.pre_ad_video_url}
              contentUrl={event_content.video_url || event_content.online_service_registration_url}
              postAdUrl={event_content.post_ad_video_url}
              onMainPhaseStart={() => trackActivity("seminar_view")}
            />
            {event_content.direct_download_url && (
              <a
                href={event_content.direct_download_url}
                target="_blank" rel="noopener noreferrer"
                onClick={() => trackActivity("material_download", { url: event_content.direct_download_url })}
                style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 8, marginTop: 12, padding: "12px 20px", background: "#334155", color: "#fff", borderRadius: 8, textDecoration: "none", fontWeight: 700, fontSize: 14 }}
              >
                <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor"><path fillRule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clipRule="evenodd"/></svg>
                {(event_content.slide_images || []).length > 0 ? "続きをダウンロード" : "資料をダウンロード"}
              </a>
            )}
          </div>
        ) : hasStarted && event_content.content_type === "booth" ? (
          <div style={{ marginBottom: 20 }}>
            <PDFCarousel
              images={event_content.slide_images || []}
              onlineServiceUrl={event_content.online_service_registration_url}
            />
            {event_content.online_service_registration_url && (
              <a
                href={event_content.online_service_registration_url}
                target="_blank" rel="noopener noreferrer"
                onClick={() => trackActivity("online_service_click", { url: event_content.online_service_registration_url })}
                style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 8, marginTop: 12, padding: "12px 20px", background: "#0d9488", color: "#fff", borderRadius: 8, textDecoration: "none", fontWeight: 700, fontSize: 14 }}
              >
                <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v3.586L7.707 9.293a1 1 0 00-1.414 1.414l3 3a1 1 0 001.414 0l3-3a1 1 0 00-1.414-1.414L11 10.586V7z" clipRule="evenodd"/></svg>
                出展企業のサービスページへ
              </a>
            )}
          </div>
        ) : (
          <div style={{ overflow: "hidden", marginBottom: 0 }}>
            {event_content.thumbnail_url ? (
              <img src={event_content.thumbnail_url} style={{ width: "100%", maxHeight: 320, objectFit: "cover", display: "block" }} />
            ) : (
              <div style={{ height: 180, background: typeColor, display: "flex", alignItems: "center", justifyContent: "center" }}>
                <span style={{ fontSize: 56 }}>{event_content.content_type === "seminar" ? "🎬" : "📄"}</span>
              </div>
            )}
          </div>
        )}

        {/* Title + Share (below thumbnail) */}
        <div style={{ textAlign: "center", padding: "20px 0 16px" }}>
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

        {/* Preview slides for registered participants (booth, before starting) */}
        {isParticipant && !hasStarted && event_content.content_type === "booth" && (event_content.slide_images || []).length > 0 && (
          <div style={{ marginBottom: 20 }}>
            <h3 style={{ fontSize: 14, fontWeight: 700, color: "#374151", marginBottom: 10 }}>プレビュー</h3>
            <PDFCarousel
              images={(event_content.slide_images || []).slice(0, 3)}
              onlineServiceUrl={null}
            />
            {(event_content.slide_images || []).length > 3 && (
              <p style={{ textAlign: "center", fontSize: 12, color: "#9ca3af", marginTop: 8 }}>
                全 {event_content.slide_images.length} ページ（利用開始で全て閲覧可能）
              </p>
            )}
          </div>
        )}

        {/* Status messages */}
        {event_content.ended && (
          <div style={{ background: "#fafaf9", border: "1px solid #e7e5e4", color: "#57534e", padding: "12px 16px", textAlign: "center", marginBottom: 16, fontWeight: 700, fontSize: 14 }}>
            このコンテンツは終了しました
          </div>
        )}

        {!event_content.started && !event_content.ended && (
          <div style={{ background: "#fafaf9", border: "1px solid #e7e5e4", color: "#78716c", padding: "12px 16px", textAlign: "center", marginBottom: 16, fontSize: 14 }}>
            サービス開始前です。開始をお待ちください。
          </div>
        )}

        {/* Start usage button for participants */}
        {isParticipant && !hasStarted && canStart && (
          <button
            onClick={handleStartUsage}
            disabled={isStarting}
            style={{
              width: "100%", padding: "14px", marginBottom: 20,
              background: typeColor, color: "#fff", border: "none",
              borderRadius: 8, fontSize: 16, fontWeight: 700,
              cursor: "pointer", boxShadow: `0 4px 14px ${typeColor}66`
            }}
          >
            {isStarting ? "..." : ctaLabel}
          </button>
        )}

        {/* LINE login CTA for non-participants */}
        {!isParticipant && line_login_url && (
          <div style={{ background: "#fafaf9", border: "1px solid #e7e5e4", padding: "24px 20px", marginBottom: 20, textAlign: "center" }}>
            <p style={{ fontSize: 14, color: "#44403c", marginBottom: 14, fontWeight: 600 }}>
              参加登録してコンテンツを利用しましょう
            </p>
            <EventLineLoginLink loginUrl={line_login_url} btnText="LINEで参加登録する" />
          </div>
        )}

        {/* Introduction */}
        {event_content.introduction && (
          <div style={{ background: "#fff", padding: "20px", marginBottom: 16, borderBottom: "1px solid #e7e5e4" }}>
            <h3 style={{ fontWeight: 700, fontSize: 15, marginBottom: 10, color: "#1c1917" }}>紹介文</h3>
            <p style={{ color: "#57534e", lineHeight: 1.8, whiteSpace: "pre-wrap", fontSize: 14 }}>{event_content.introduction}</p>
          </div>
        )}

        {/* Description */}
        {event_content.description && (
          <div style={{ background: "#fff", padding: "20px", marginBottom: 16, borderBottom: "1px solid #e7e5e4" }}>
            <h3 style={{ fontWeight: 700, fontSize: 15, marginBottom: 10, color: "#1c1917" }}>説明</h3>
            <p style={{ color: "#57534e", lineHeight: 1.8, whiteSpace: "pre-wrap", fontSize: 14 }}>{event_content.description}</p>
          </div>
        )}

        {/* Speakers */}
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
                      <p style={{ fontSize: 13, color: "#78716c", lineHeight: 1.7, whiteSpace: "pre-wrap" }}>{speaker.introduction}</p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Exhibitor (fallback) */}
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
                <div style={{ fontWeight: 700, fontSize: 16, color: "#1c1917", marginBottom: 6 }}>{event_content.exhibitor_staff.name}</div>
                {event_content.exhibitor_staff.introduction && (
                  <p style={{ fontSize: 13, color: "#78716c", lineHeight: 1.7, whiteSpace: "pre-wrap" }}>{event_content.exhibitor_staff.introduction}</p>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Upsell */}
        {(event_content.upsell_booking_enabled || event_content.monitor_enabled) && hasStarted && (
          <div style={{ marginBottom: 20 }}>
            <UpsellSection
              content={event_content}
              upsellConsultationUrl={upsell_consultation_url}
              monitorApplyUrl={monitor_apply_url}
              onTrackActivity={trackActivity}
            />
          </div>
        )}
      </div>

      <ShareModal
        isOpen={shareOpen}
        onClose={() => setShareOpen(false)}
        title="このコンテンツをシェアする"
        shareTitle={event_content.title}
        thumbnailUrl={event_content.thumbnail_url || null}
        shareUrl={typeof window !== "undefined" ? window.location.href : ""}
      />
    </div>
  );
};

export default EventContentShow;
