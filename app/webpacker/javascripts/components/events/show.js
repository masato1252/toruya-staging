"use strict"

import React, { useState, useEffect, useRef, useCallback } from "react";
import { LineLoginBtn } from "shared/booking";

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
            border: "1px solid #e7e5e4", background: "#fafaf9"
          }}>
            {thumbnailUrl && (
              <img src={thumbnailUrl} style={{ width: "100%", height: 160, objectFit: "cover", display: "block" }} />
            )}
            <div style={{ padding: "12px 16px" }}>
              <div style={{ fontWeight: 700, fontSize: 14, color: "#1c1917", lineHeight: 1.5 }}>{shareTitle}</div>
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
                color: "#44403c", outline: "none", minWidth: 0
              }}
            />
          </div>

          <button
            onClick={handleCopy}
            style={{
              width: "100%", padding: "12px", border: "1px solid #d6d3d1",
              borderRadius: 10, background: "#fff", cursor: "pointer",
              display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
              fontSize: 14, color: "#44403c", fontWeight: 600, marginBottom: 20
            }}
          >
            <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor"><path d="M8 3a1 1 0 011-1h2a1 1 0 110 2H9a1 1 0 01-1-1z"/><path d="M6 3a2 2 0 00-2 2v11a2 2 0 002 2h8a2 2 0 002-2V5a2 2 0 00-2-2 3 3 0 01-3 3H9a3 3 0 01-3-3z"/></svg>
            {copied ? "コピーしました" : "URLをコピー"}
          </button>

          <div style={{
            display: "flex", justifyContent: "center", gap: 24,
            borderTop: "1px solid #e7e5e4", paddingTop: 20
          }}>
            {platforms.map(p => (
              <a
                key={p.name}
                href={p.href}
                target="_blank"
                rel="noopener noreferrer"
                style={{
                  display: "flex", flexDirection: "column", alignItems: "center", gap: 6,
                  textDecoration: "none", color: "#44403c"
                }}
              >
                <div style={{
                  width: 48, height: 48, borderRadius: "50%", border: "1px solid #e7e5e4",
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

const EventLineLoginLink = ({ loginUrl, btnText, style }) => {
  if (!loginUrl) return null;

  return (
    <a
      href={loginUrl}
      style={{
        display: "inline-flex", alignItems: "center", gap: 8,
        padding: "14px 32px", background: "#06c755", color: "#fff",
        borderRadius: 30, fontSize: 16, fontWeight: "bold",
        textDecoration: "none", cursor: "pointer", boxShadow: "0 4px 14px rgba(6,199,85,0.4)",
        ...style
      }}
    >
      <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M19.365 9.863c.349 0 .63.285.63.631 0 .345-.281.63-.63.63H17.61v1.125h1.755c.349 0 .63.283.63.63 0 .344-.281.629-.63.629h-2.386c-.345 0-.627-.285-.627-.629V8.108c0-.345.282-.63.63-.63h2.386c.346 0 .627.285.627.63 0 .349-.281.63-.63.63H17.61v1.125h1.755zm-3.855 3.016c0 .27-.174.51-.432.596-.064.021-.133.031-.199.031-.211 0-.391-.09-.51-.25l-2.443-3.317v2.94c0 .344-.279.629-.631.629-.346 0-.626-.285-.626-.629V8.108c0-.27.173-.51.43-.595.06-.023.136-.033.194-.033.195 0 .375.104.495.254l2.462 3.33V8.108c0-.345.282-.63.63-.63.345 0 .63.285.63.63v4.771zm-5.741 0c0 .344-.282.629-.631.629-.345 0-.627-.285-.627-.629V8.108c0-.345.282-.63.63-.63.346 0 .628.285.628.63v4.771zm-2.466.629H4.917c-.345 0-.63-.285-.63-.629V8.108c0-.345.285-.63.63-.63.348 0 .63.285.63.63v4.141h1.756c.348 0 .629.283.629.63 0 .344-.282.629-.629.629M24 10.314C24 4.943 18.615.572 12 .572S0 4.943 0 10.314c0 4.811 4.27 8.842 10.035 9.608.391.082.923.258 1.058.59.12.301.079.766.038 1.08l-.164 1.02c-.045.301-.24 1.186 1.049.645 1.291-.539 6.916-4.078 9.436-6.975C23.176 14.393 24 12.458 24 10.314"/></svg>
      {btnText}
    </a>
  );
};

const StatusBadge = ({ content }) => {
  if (content.ended) return <span style={{ background: "#78716c", color: "#fff", fontSize: 11, padding: "3px 10px", borderRadius: 12, fontWeight: 600 }}>終了</span>;
  if (!content.started) return <span style={{ background: "#64748b", color: "#fff", fontSize: 11, padding: "3px 10px", borderRadius: 12, fontWeight: 600 }}>開始前</span>;
  if (content.capacity_full) return <span style={{ background: "#b91c1c", color: "#fff", fontSize: 11, padding: "3px 10px", borderRadius: 12, fontWeight: 600 }}>満員</span>;
  return <span style={{ background: "#0d9488", color: "#fff", fontSize: 11, padding: "3px 10px", borderRadius: 12, fontWeight: 600 }}>受付中</span>;
};

const ContentCard = ({ content, eventSlug, isParticipant, lineLoginUrl }) => {
  const ctaLabel = () => "詳しく見る";

  return (
    <div style={{
      background: "#fff", overflow: "hidden",
      border: "1px solid #e7e5e4",
      marginBottom: 16,
      boxShadow: "0 1px 4px rgba(0,0,0,0.06), 0 4px 12px rgba(0,0,0,0.03)"
    }}>
      <a href={`/${eventSlug}/event_contents/${content.id}`} style={{ textDecoration: "none", color: "inherit" }}>
        {content.thumbnail_url ? (
          <div style={{ position: "relative", width: "100%", paddingBottom: "52.5%" }}>
            <img src={content.thumbnail_url} style={{ position: "absolute", top: 0, left: 0, width: "100%", height: "100%", objectFit: "cover", display: "block" }} />
          </div>
        ) : (
          <div style={{ height: 120, background: content.content_type === "seminar" ? "linear-gradient(135deg, #1e293b, #334155)" : "linear-gradient(135deg, #134e4a, #0d9488)", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <span style={{ fontSize: 40 }}>{content.content_type === "seminar" ? "🎬" : "📄"}</span>
          </div>
        )}
      </a>

      <div style={{ padding: "16px 20px" }}>
        <div style={{ display: "flex", gap: 6, marginBottom: 8 }}>
          <StatusBadge content={content} />
          <span style={{
            background: content.content_type === "seminar" ? "#334155" : "#0d9488",
            color: "#fff", fontSize: 11, padding: "3px 10px", borderRadius: 12, fontWeight: 600
          }}>
            {content.content_type === "seminar" ? "セミナー" : "展示ブース"}
          </span>
        </div>
        <a href={`/${eventSlug}/event_contents/${content.id}`} style={{ textDecoration: "none", color: "inherit" }}>
          <h3 style={{ fontWeight: 700, fontSize: 17, marginBottom: 8, lineHeight: 1.4, color: "#1c1917" }}>{content.title}</h3>
        </a>

        {content.introduction && (
          <p style={{ color: "#78716c", fontSize: 13, lineHeight: 1.7, marginBottom: 12, whiteSpace: "pre-wrap", display: "-webkit-box", WebkitLineClamp: 3, WebkitBoxOrient: "vertical", overflow: "hidden" }}>
            {content.introduction}
          </p>
        )}

        {(content.speakers || []).length > 0 ? (
          <div style={{ marginBottom: 14, display: "flex", flexDirection: "column", gap: 6 }}>
            {content.speakers.map((speaker, idx) => (
              <div key={idx} style={{ display: "flex", alignItems: "center", gap: 10, padding: "8px 12px", background: "#fafaf9" }}>
                {speaker.profile_image_url ? (
                  <img src={speaker.profile_image_url} style={{ width: 36, height: 36, borderRadius: "50%", objectFit: "cover", flexShrink: 0 }} />
                ) : (
                  <div style={{ width: 36, height: 36, borderRadius: "50%", background: "#e7e5e4", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, fontSize: 16, color: "#a8a29e" }}>👤</div>
                )}
                <div>
                  {speaker.position_title && (
                    <div style={{ fontSize: 11, color: "#a8a29e" }}>{speaker.position_title}</div>
                  )}
                  <div style={{ fontSize: 13, fontWeight: 600, color: "#44403c" }}>{speaker.name}</div>
                </div>
              </div>
            ))}
          </div>
        ) : content.exhibitor_staff ? (
          <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 14, padding: "10px 12px", background: "#fafaf9" }}>
            {content.exhibitor_staff.picture_url && (
              content.content_type === "booth" && !content.exhibitor_staff.position ? (
                <img src={content.exhibitor_staff.picture_url} style={{ width: 40, height: 40, objectFit: "contain", flexShrink: 0, background: "#fff" }} />
              ) : (
                <img src={content.exhibitor_staff.picture_url} style={{ width: 40, height: 40, borderRadius: "50%", objectFit: "cover", flexShrink: 0 }} />
              )
            )}
            <div>
              {content.exhibitor_staff.position && (
                <div style={{ fontSize: 11, color: "#a8a29e" }}>{content.exhibitor_staff.position}</div>
              )}
              <div style={{ fontSize: 13, fontWeight: 600, color: "#44403c" }}>{content.exhibitor_staff.name}</div>
            </div>
          </div>
        ) : null}

        {content.capacity && !content.ended && (
          <div style={{ fontSize: 12, color: "#a8a29e", marginBottom: 12 }}>
            残り {Math.max(0, content.capacity - content.usage_count)}名
          </div>
        )}

        <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
          {isParticipant && !content.ended ? (
            <a
              href={`/${eventSlug}/event_contents/${content.id}`}
              style={{
                flex: 1, display: "block", padding: "12px 16px", textAlign: "center",
                background: "#0d9488",
                color: "#fff", borderRadius: 8, fontSize: 14, fontWeight: 700,
                textDecoration: "none"
              }}
            >
              {ctaLabel()}
            </a>
          ) : (
            <a
              href={`/${eventSlug}/event_contents/${content.id}`}
              style={{
                flex: 1, display: "block", padding: "12px 16px", textAlign: "center",
                background: "#f5f5f4", color: "#44403c", borderRadius: 8,
                fontSize: 14, fontWeight: 600, textDecoration: "none"
              }}
            >
              詳細を見る
            </a>
          )}
        </div>
      </div>
    </div>
  );
};

const RecommendationCarousel = ({ contents, eventSlug }) => {
  const [current, setCurrent] = useState(0);
  const [swipeOffset, setSwipeOffset] = useState(0);
  const [isSwiping, setIsSwiping] = useState(false);
  const timerRef = useRef(null);
  const touchStart = useRef(null);
  const trackRef = useRef(null);
  const total = contents.length;

  const goTo = useCallback((idx) => {
    setCurrent((idx + total) % total);
  }, [total]);

  useEffect(() => {
    if (total <= 1) return;
    timerRef.current = setInterval(() => {
      setCurrent(prev => (prev + 1) % total);
    }, 8000);
    return () => clearInterval(timerRef.current);
  }, [total]);

  const resetTimer = () => {
    if (timerRef.current) clearInterval(timerRef.current);
    if (total <= 1) return;
    timerRef.current = setInterval(() => {
      setCurrent(prev => (prev + 1) % total);
    }, 8000);
  };

  const handleTouchStart = (e) => {
    touchStart.current = { x: e.touches[0].clientX, y: e.touches[0].clientY, time: Date.now() };
    setIsSwiping(true);
    if (timerRef.current) clearInterval(timerRef.current);
  };

  const handleTouchMove = (e) => {
    if (!touchStart.current) return;
    const dx = e.touches[0].clientX - touchStart.current.x;
    setSwipeOffset(dx);
  };

  const handleTouchEnd = () => {
    if (!touchStart.current) return;
    const elapsed = Date.now() - touchStart.current.time;
    const threshold = Math.abs(swipeOffset) > 50 || (Math.abs(swipeOffset) > 20 && elapsed < 300);
    if (threshold) {
      if (swipeOffset < 0) goTo(current + 1);
      else goTo(current - 1);
    }
    touchStart.current = null;
    setSwipeOffset(0);
    setIsSwiping(false);
    resetTimer();
  };

  const trackWidth = trackRef.current ? trackRef.current.offsetWidth : 1;
  const swipePct = (swipeOffset / trackWidth) * 100;

  return (
    <div style={{ background: "#134e4a", padding: "24px 16px" }}>
      <div style={{ maxWidth: 720, margin: "0 auto" }}>
        <h2 style={{ fontSize: 17, fontWeight: 800, marginBottom: 16, color: "#ccfbf1" }}>
          🎯 あなたのお悩みにおすすめ
        </h2>
        <div style={{ position: "relative" }}>
          <div
            ref={trackRef}
            style={{ overflow: "hidden", touchAction: "pan-y" }}
            onTouchStart={handleTouchStart}
            onTouchMove={handleTouchMove}
            onTouchEnd={handleTouchEnd}
          >
            <div style={{
              display: "flex", alignItems: "stretch",
              transition: isSwiping ? "none" : "transform 0.4s ease",
              transform: `translateX(${-current * 100 + swipePct}%)`
            }}>
              {contents.map(content => (
                <a
                  key={content.id}
                  href={`/${eventSlug}/event_contents/${content.id}`}
                  style={{
                    flex: "0 0 100%", minWidth: 0,
                    display: "flex",
                    textDecoration: "none", color: "inherit",
                    padding: "0 4px", boxSizing: "border-box"
                  }}
                >
                  <div style={{
                    background: "#fff", overflow: "hidden",
                    border: "1px solid #e7e5e4",
                    display: "flex", flexDirection: "column", width: "100%"
                  }}>
                    {content.thumbnail_url ? (
                      <img src={content.thumbnail_url} style={{ width: "100%", height: 160, objectFit: "cover", display: "block", flexShrink: 0 }} />
                    ) : (
                      <div style={{
                        height: 100, flexShrink: 0,
                        background: content.content_type === "seminar"
                          ? "linear-gradient(135deg, #1e293b, #334155)"
                          : "linear-gradient(135deg, #115e59, #0d9488)",
                        display: "flex", alignItems: "center", justifyContent: "center"
                      }}>
                        <span style={{ fontSize: 32 }}>{content.content_type === "seminar" ? "🎬" : "📄"}</span>
                      </div>
                    )}
                    <div style={{ padding: "12px 16px", flex: 1, display: "flex", flexDirection: "column" }}>
                      <div style={{ display: "flex", gap: 4, marginBottom: 6 }}>
                        <span style={{
                          fontSize: 10, padding: "2px 8px", borderRadius: 10, fontWeight: 600, color: "#fff",
                          background: content.content_type === "seminar" ? "#334155" : "#0d9488"
                        }}>
                          {content.content_type === "seminar" ? "セミナー" : "展示ブース"}
                        </span>
                      </div>
                      <div style={{ fontWeight: 700, fontSize: 15, lineHeight: 1.4, color: "#1c1917",
                        display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden",
                        flex: 1
                      }}>
                        {content.title}
                      </div>
                      {content.exhibitor_staff && (
                        <div style={{ fontSize: 12, color: "#78716c", marginTop: 4 }}>{content.exhibitor_staff.name}</div>
                      )}
                    </div>
                  </div>
                </a>
              ))}
            </div>
          </div>

          {total > 1 && (
            <>
              <button
                onClick={() => { goTo(current - 1); resetTimer(); }}
                style={{
                  position: "absolute", left: -4, top: "50%", transform: "translateY(-50%)",
                  background: "rgba(255,255,255,0.9)", border: "none",
                  width: 34, height: 34, borderRadius: "50%", cursor: "pointer",
                  display: "flex", alignItems: "center", justifyContent: "center",
                  boxShadow: "0 2px 8px rgba(0,0,0,0.15)", padding: 0
                }}
              ><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#134e4a" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"/></svg></button>
              <button
                onClick={() => { goTo(current + 1); resetTimer(); }}
                style={{
                  position: "absolute", right: -4, top: "50%", transform: "translateY(-50%)",
                  background: "rgba(255,255,255,0.9)", border: "none",
                  width: 34, height: 34, borderRadius: "50%", cursor: "pointer",
                  display: "flex", alignItems: "center", justifyContent: "center",
                  boxShadow: "0 2px 8px rgba(0,0,0,0.15)", padding: 0
                }}
              ><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#134e4a" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="9 6 15 12 9 18"/></svg></button>
            </>
          )}
        </div>

        {total > 1 && (
          <div style={{ display: "flex", justifyContent: "center", gap: 8, marginTop: 14 }}>
            {contents.map((_, i) => (
              <button
                key={i}
                onClick={() => { goTo(i); resetTimer(); }}
                style={{
                  width: i === current ? 20 : 8, height: 8,
                  borderRadius: 4, border: "none", padding: 0, cursor: "pointer",
                  background: i === current ? "#5eead4" : "rgba(255,255,255,0.3)",
                  transition: "all 0.3s"
                }}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

const EventShow = ({ props }) => {
  const { event, line_login_url, add_friend_url, current_event_path } = props;
  const [activeTab, setActiveTab] = useState("all");
  const [shareOpen, setShareOpen] = useState(false);

  const seminars = event.contents ? event.contents.filter(c => c.content_type === "seminar") : [];
  const booths = event.contents ? event.contents.filter(c => c.content_type === "booth") : [];

  const visibleContents = activeTab === "seminar" ? seminars
    : activeTab === "booth" ? booths
    : (event.contents || []);

  return (
    <div style={{ minHeight: "100vh", background: "#fafaf9" }}>
      {/* Hero */}
      <div style={{
        background: event.hero_image_url
          ? `url(${event.hero_image_url}) center/cover no-repeat`
          : "linear-gradient(135deg, #0f172a 0%, #1e293b 40%, #334155 100%)",
        color: "#fff", padding: "48px 20px 40px", position: "relative", overflow: "hidden"
      }}>
        {event.hero_image_url && (
          <div style={{ position: "absolute", top: 0, left: 0, right: 0, bottom: 0, background: "rgba(0,0,0,0.5)" }} />
        )}
        {!event.hero_image_url && (
          <div style={{
            position: "absolute", top: 0, left: 0, right: 0, bottom: 0, opacity: 0.06,
            backgroundImage: "radial-gradient(circle at 25% 25%, #fff 1px, transparent 1px), radial-gradient(circle at 75% 75%, #fff 1px, transparent 1px)",
            backgroundSize: "40px 40px"
          }} />
        )}
        <div style={{ maxWidth: 720, margin: "0 auto", position: "relative", zIndex: 1 }}>
          {event.is_participant && (
            <div style={{
              display: "inline-flex", alignItems: "center", gap: 6,
              background: "rgba(13,148,136,0.2)", border: "1px solid rgba(13,148,136,0.5)",
              borderRadius: 20, padding: "6px 14px", marginBottom: 16, fontSize: 13, fontWeight: 600, color: "#5eead4"
            }}>
              <svg width="14" height="14" viewBox="0 0 20 20" fill="currentColor"><path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd"/></svg>
              参加登録済み
            </div>
          )}

          <h1 style={{ fontSize: 28, fontWeight: 800, marginBottom: 12, lineHeight: 1.3, letterSpacing: "-0.02em" }}>
            {event.title}
          </h1>

          {event.start_at && (
            <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 16, fontSize: 14, color: "rgba(255,255,255,0.65)" }}>
              <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor"><path fillRule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clipRule="evenodd"/></svg>
              {new Date(event.start_at).toLocaleDateString("ja-JP", { year: "numeric", month: "long", day: "numeric" })}
              {event.end_at && ` 〜 ${new Date(event.end_at).toLocaleDateString("ja-JP", { month: "long", day: "numeric" })}`}
            </div>
          )}

          {event.description && (
            <p style={{ fontSize: 14, lineHeight: 1.8, color: "rgba(255,255,255,0.6)", whiteSpace: "pre-wrap", marginBottom: 24 }}>
              {event.description}
            </p>
          )}

          {!event.is_participant && line_login_url && (
            <EventLineLoginLink loginUrl={line_login_url} btnText="LINEで参加登録する" />
          )}
        </div>
      </div>

      {/* Share bar */}
      <div style={{ background: "#fff", borderBottom: "1px solid #e7e5e4", padding: "12px 20px" }}>
        <div style={{ maxWidth: 720, margin: "0 auto", display: "flex", alignItems: "center", justifyContent: "flex-end" }}>
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
      </div>

      {/* Recommendations Carousel */}
      {event.is_participant && (event.recommended_content_ids || []).length > 0 && (() => {
        const recContents = (event.recommended_content_ids || [])
          .map(id => (event.contents || []).find(c => c.id === id))
          .filter(Boolean);
        if (recContents.length === 0) return null;
        return (
          <RecommendationCarousel contents={recContents} eventSlug={event.slug} />
        );
      })()}

      {/* Tabs */}
      {seminars.length > 0 && booths.length > 0 && (
        <div style={{ background: "#fff", borderBottom: "1px solid #e7e5e4", position: "sticky", top: 0, zIndex: 10 }}>
          <div style={{ maxWidth: 720, margin: "0 auto", display: "flex" }}>
            {[["all", `すべて (${(event.contents || []).length})`], ["seminar", `セミナー (${seminars.length})`], ["booth", `展示ブース (${booths.length})`]].map(([val, label]) => (
              <button
                key={val}
                onClick={() => setActiveTab(val)}
                style={{
                  flex: 1, padding: "14px 8px", background: "none", border: "none",
                  borderBottom: `3px solid ${activeTab === val ? "#0d9488" : "transparent"}`,
                  color: activeTab === val ? "#0d9488" : "#a8a29e",
                  fontWeight: activeTab === val ? 700 : 500,
                  cursor: "pointer", fontSize: 13, transition: "all 0.2s"
                }}
              >
                {label}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Content list */}
      <div style={{ maxWidth: 720, margin: "0 auto", padding: "16px 16px 24px" }}>
        {visibleContents.length === 0 ? (
          <div style={{ textAlign: "center", padding: "60px 20px" }}>
            <div style={{ fontSize: 48, marginBottom: 12 }}>📋</div>
            <p style={{ color: "#a8a29e", fontSize: 15 }}>コンテンツはまだありません</p>
          </div>
        ) : (
          visibleContents.map(content => (
            <ContentCard
              key={content.id}
              content={content}
              eventSlug={event.slug}
              isParticipant={event.is_participant}
              lineLoginUrl={line_login_url}
            />
          ))
        )}
      </div>

      {/* Footer CTA */}
      {!event.is_participant && line_login_url && (
        <div style={{
          position: "sticky", bottom: 0, left: 0, right: 0, zIndex: 20,
          background: "rgba(255,255,255,0.95)", backdropFilter: "blur(8px)",
          borderTop: "1px solid #e7e5e4", padding: "12px 20px"
        }}>
          <div style={{ maxWidth: 720, margin: "0 auto", display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12 }}>
            <span style={{ fontSize: 13, fontWeight: 600, color: "#44403c" }}>参加登録して全コンテンツにアクセス</span>
            <EventLineLoginLink loginUrl={line_login_url} btnText="参加登録" style={{ flexShrink: 0 }} />
          </div>
        </div>
      )}

      <ShareModal
        isOpen={shareOpen}
        onClose={() => setShareOpen(false)}
        title="このイベントをシェアする"
        shareTitle={event.title}
        thumbnailUrl={event.hero_image_url || null}
        shareUrl={current_event_path}
      />
    </div>
  );
};

export default EventShow;
