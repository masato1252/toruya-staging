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

// "M月D日(曜日)" 形式で日付をフォーマット。nil/undefined の場合は null を返す。
const formatJaDateWithWeekday = (value) => {
  if (!value) return null;
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return null;
  const weekdays = ["日", "月", "火", "水", "木", "金", "土"];
  return `${d.getMonth() + 1}月${d.getDate()}日(${weekdays[d.getDay()]})`;
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
  if (content.capacity_full) return <span style={{ background: "#CA4E0E", color: "#fff", fontSize: 11, padding: "3px 10px", borderRadius: 12, fontWeight: 600 }}>満員</span>;
  return <span style={{ background: "#488479", color: "#fff", fontSize: 11, padding: "3px 10px", borderRadius: 12, fontWeight: 600 }}>受付中</span>;
};

// サムネ未設定時のフォールバック表示。
// 薄いグレー背景 + 中央にイベントロゴ（無ければコンテンツ種別アイコン）。
const ThumbnailFallback = ({ eventLogoUrl, contentType }) => (
  <div style={{
    position: "absolute", top: 0, left: 0, width: "100%", height: "100%",
    background: "#464342",
    display: "flex", alignItems: "center", justifyContent: "center"
  }}>
    {eventLogoUrl ? (
      <img
        src={eventLogoUrl}
        alt=""
        style={{ maxWidth: "32%", maxHeight: "48%", width: "auto", height: "auto", objectFit: "contain", display: "block" }}
      />
    ) : (
      <span style={{ fontSize: 36, opacity: 0.6, color: "#fff" }}>{contentType === "seminar" ? "🎬" : "📄"}</span>
    )}
  </div>
);

const ContentCard = ({ content, eventSlug, isParticipant, lineLoginUrl, disableLinks = false, previewable = false, eventLogoUrl = null }) => {
  const ctaLabel = () => "詳しく見る";
  const contentHref = `/${eventSlug}/event_contents/${content.id}`;
  // 開催前(disableLinks)でも、参加登録済 + プレビュー権限ありなら詳細リンクを許可しラベルを「プレビュー」へ。
  const showPreviewButton = disableLinks && previewable && isParticipant;
  const linksEnabled = !disableLinks || showPreviewButton;
  const ThumbWrapper = linksEnabled ? "a" : "div";
  const thumbWrapperProps = linksEnabled
    ? { href: contentHref, style: { textDecoration: "none", color: "inherit", display: "block" } }
    : { style: { display: "block" } };
  const TitleWrapper = linksEnabled ? "a" : "div";
  const titleWrapperProps = linksEnabled
    ? { href: contentHref, style: { textDecoration: "none", color: "inherit" } }
    : {};

  return (
    <div style={{
      background: "#fff", overflow: "hidden",
      border: "1px solid #e7e5e4",
      marginBottom: 16,
      boxShadow: "0 1px 4px rgba(0,0,0,0.06), 0 4px 12px rgba(0,0,0,0.03)"
    }}>
      <ThumbWrapper {...thumbWrapperProps}>
        <div style={{ position: "relative", width: "100%", paddingBottom: "52.5%" }}>
          {content.thumbnail_url ? (
            <img src={content.thumbnail_url} style={{ position: "absolute", top: 0, left: 0, width: "100%", height: "100%", objectFit: "cover", display: "block" }} />
          ) : (
            <ThumbnailFallback eventLogoUrl={eventLogoUrl} contentType={content.content_type} />
          )}
        </div>
      </ThumbWrapper>

      <div style={{ padding: "16px 20px" }}>
        <div style={{ display: "flex", gap: 6, marginBottom: 8 }}>
          <StatusBadge content={content} />
          <span style={{
            background: content.content_type === "seminar" ? "#B95526" : "#488479",
            color: "#fff", fontSize: 11, padding: "3px 10px", borderRadius: 12, fontWeight: 600
          }}>
            {content.content_type === "seminar" ? "セミナー" : "展示ブース"}
          </span>
        </div>
        <TitleWrapper {...titleWrapperProps}>
          <h3 style={{ fontWeight: 700, fontSize: 17, marginBottom: 8, lineHeight: 1.4, color: "#1c1917" }}>{content.title}</h3>
        </TitleWrapper>

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

        {linksEnabled && (
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            {showPreviewButton ? (
              <a
                href={contentHref}
                style={{
                  flex: 1, display: "block", padding: "12px 16px", textAlign: "center",
                  background: "#fff", color: "#488479", border: "2px solid #488479",
                  borderRadius: 8, fontSize: 14, fontWeight: 700, textDecoration: "none"
                }}
              >
                プレビュー
              </a>
            ) : isParticipant && !content.ended ? (
              <a
                href={contentHref}
                style={{
                  flex: 1, display: "block", padding: "12px 16px", textAlign: "center",
                  background: "#488479",
                  color: "#fff", borderRadius: 8, fontSize: 14, fontWeight: 700,
                  textDecoration: "none"
                }}
              >
                {ctaLabel()}
              </a>
            ) : (
              <a
                href={contentHref}
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
        )}
      </div>
    </div>
  );
};

const RecommendationCarousel = ({ contents, eventSlug, disableLinks = false, eventLogoUrl = null, isParticipant = false, canPreviewAll = false, previewableContentIds = [] }) => {
  // 開催前(disableLinks)でも、参加登録済 + プレビュー権限ありのコンテンツはリンクを許可。
  const previewableSet = new Set(previewableContentIds);
  const isPreviewable = (content) => isParticipant && (canPreviewAll || previewableSet.has(content.id));
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
    <div style={{ background: "#488479", padding: "24px 16px" }}>
      <div style={{ maxWidth: 720, margin: "0 auto" }}>
        <h2 style={{ fontSize: 17, fontWeight: 800, marginBottom: 16, color: "#FAEACB" }}>
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
              {contents.map(content => {
                const linkActive = !disableLinks || isPreviewable(content);
                const CardWrapper = linkActive ? "a" : "div";
                const cardWrapperProps = linkActive
                  ? {
                      href: `/${eventSlug}/event_contents/${content.id}`,
                      style: {
                        flex: "0 0 100%", minWidth: 0,
                        display: "flex",
                        textDecoration: "none", color: "inherit",
                        padding: "0 4px", boxSizing: "border-box"
                      }
                    }
                  : {
                      style: {
                        flex: "0 0 100%", minWidth: 0,
                        display: "flex",
                        color: "inherit",
                        padding: "0 4px", boxSizing: "border-box"
                      }
                    };
                return (
                <CardWrapper
                  key={content.id}
                  {...cardWrapperProps}
                >
                  <div style={{
                    background: "#fff", overflow: "hidden",
                    border: "1px solid #e7e5e4",
                    display: "flex", flexDirection: "column", width: "100%"
                  }}>
                    <div style={{ position: "relative", width: "100%", paddingBottom: "52.5%", flexShrink: 0 }}>
                      {content.thumbnail_url ? (
                        <img src={content.thumbnail_url} style={{ position: "absolute", top: 0, left: 0, width: "100%", height: "100%", objectFit: "cover", display: "block" }} />
                      ) : (
                        <ThumbnailFallback eventLogoUrl={eventLogoUrl} contentType={content.content_type} />
                      )}
                    </div>
                    <div style={{ padding: "12px 16px", flex: 1, display: "flex", flexDirection: "column" }}>
                      <div style={{ display: "flex", gap: 4, marginBottom: 6, flexWrap: "wrap" }}>
                        <span style={{
                          fontSize: 10, padding: "2px 8px", borderRadius: 10, fontWeight: 600, color: "#fff",
                          background: content.content_type === "seminar" ? "#B95526" : "#488479"
                        }}>
                          {content.content_type === "seminar" ? "セミナー" : "展示ブース"}
                        </span>
                        {disableLinks && isPreviewable(content) && (
                          <span style={{
                            fontSize: 10, padding: "2px 8px", borderRadius: 10, fontWeight: 700,
                            background: "#fff", color: "#488479", border: "1px solid #488479"
                          }}>プレビュー</span>
                        )}
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
                </CardWrapper>
                );
              })}
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
              ><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#488479" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"/></svg></button>
              <button
                onClick={() => { goTo(current + 1); resetTimer(); }}
                style={{
                  position: "absolute", right: -4, top: "50%", transform: "translateY(-50%)",
                  background: "rgba(255,255,255,0.9)", border: "none",
                  width: 34, height: 34, borderRadius: "50%", cursor: "pointer",
                  display: "flex", alignItems: "center", justifyContent: "center",
                  boxShadow: "0 2px 8px rgba(0,0,0,0.15)", padding: 0
                }}
              ><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#488479" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="9 6 15 12 9 18"/></svg></button>
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
                  background: i === current ? "#FCBE46" : "rgba(255,255,255,0.3)",
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

// 口数計算。Ruby 側の EventStampEntry.compute_tickets と同ロジック。
// material_download と seminar_view は 3件で 1口、upsell_consultation / monitor_apply は 1件で 1口。
const computeTickets = (entries) => {
  const count = (t) => entries.filter((e) => e.action_type === t).length;
  return (
    Math.floor(count("material_download") / 3) +
    Math.floor(count("seminar_view") / 3) +
    count("upsell_consultation") +
    count("monitor_apply")
  );
};

// 期間(弾)のタブラベル用に MM/DD 形式を返す。
const formatMonthDay = (isoDate) => {
  if (!isoDate) return null;
  const d = new Date(`${isoDate}T00:00:00`);
  if (Number.isNaN(d.getTime())) return null;
  return `${String(d.getMonth() + 1).padStart(2, "0")}/${String(d.getDate()).padStart(2, "0")}`;
};

// 期間に含まれるか判定。start_on = その日の 00:00:00、end_on = その日の 23:59:59.999 まで含む。
const isEntryInPhase = (entry, phase) => {
  const t = new Date(entry.created_at).getTime();
  const s = phase.start_on ? new Date(`${phase.start_on}T00:00:00`).getTime() : -Infinity;
  const e = phase.end_on ? new Date(`${phase.end_on}T23:59:59.999`).getTime() : Infinity;
  return t >= s && t <= e;
};

// 期間がタイトル/開始日/終了日が揃っていない場合でも、設定された情報でフィルタ判定を行う。
const phaseContainsNow = (phase) => {
  const now = Date.now();
  const s = phase.start_on ? new Date(`${phase.start_on}T00:00:00`).getTime() : -Infinity;
  const e = phase.end_on ? new Date(`${phase.end_on}T23:59:59.999`).getTime() : Infinity;
  return now >= s && now <= e;
};

// MM/DD 形式に揃える（スタンプ押印日表示用）。
const formatStampDate = (createdAt) => {
  const d = new Date(createdAt);
  if (Number.isNaN(d.getTime())) return "";
  return `${String(d.getMonth() + 1).padStart(2, "0")}/${String(d.getDate()).padStart(2, "0")}`;
};

// スタンプラリーで表示する種別の固定順と、1口あたりのスタンプ数。
const STAMP_TYPE_DEFS = [
  { type: "material_download",   label: "資料DL",       perTicket: 3 },
  { type: "seminar_view",        label: "動画視聴",     perTicket: 3 },
  { type: "upsell_consultation", label: "無料相談予約", perTicket: 1 },
  { type: "monitor_apply",       label: "モニター応募", perTicket: 1 }
];

// 1スタンプ枠のサークル表示。filled=押印済み(中身=MM/DD)、未押印=「未」枠。
const StampCircle = ({ filled, text }) => (
  <div style={{
    width: 60, height: 60, borderRadius: "50%",
    border: filled ? "2px solid #CA4E0E" : "2px dashed #d6d3d1",
    background: filled ? "rgba(202,78,14,0.06)" : "#fff",
    boxShadow: filled ? "0 2px 6px rgba(202,78,14,0.18)" : "none",
    display: "flex", alignItems: "center", justifyContent: "center",
    flexShrink: 0
  }}>
    <span style={{
      fontSize: 12, fontWeight: 700,
      color: filled ? "#CA4E0E" : "#a8a29e",
      textAlign: "center", lineHeight: 1.2,
      letterSpacing: filled ? "0.02em" : 0
    }}>
      {text}
    </span>
  </div>
);

// 1口=1ブロック。ヘッダ中央に種別名、右端に「1口」、中央揃えで perTicket 個のスタンプ枠。
// completed=true の場合は赤枠 + ブロック全体に「達成済」のタスキ(右上→左下の斜めバンド)を被せる。
const TicketBlock = ({ label, perTicket, filledStamps, completed = false }) => (
  <div style={{
    position: "relative", overflow: "hidden",
    background: "#fff",
    border: completed ? "2px solid #c0382b" : "1px solid #e7e5e4",
    borderRadius: 8, padding: "12px 16px", marginBottom: 10
  }}>
    <div style={{
      display: "grid", gridTemplateColumns: "1fr auto 1fr",
      alignItems: "center", marginBottom: 12
    }}>
      <span />
      <span style={{ fontSize: 13, fontWeight: 800, color: "#44403c", textAlign: "center" }}>{label}</span>
      <span style={{ fontSize: 12, fontWeight: 700, color: "#CA4E0E", textAlign: "right" }}>1口</span>
    </div>
    <div style={{ display: "flex", gap: 12, justifyContent: "center" }}>
      {Array.from({ length: perTicket }).map((_, i) => {
        const stamp = filledStamps[i];
        const filled = !!stamp;
        const text = filled ? formatStampDate(stamp.created_at) : "未";
        return <StampCircle key={i} filled={filled} text={text} />;
      })}
    </div>

    {completed && (
      <div
        aria-hidden
        style={{
          position: "absolute", top: 0, left: 0, right: 0, bottom: 0,
          pointerEvents: "none", overflow: "hidden"
        }}
      >
        {/* 斜めのタスキ帯（左上から右下へ斜めに掛かる） */}
        <div style={{
          position: "absolute",
          top: "50%", left: "-25%",
          width: "150%", padding: "8px 0",
          background: "rgba(192,56,43,0.45)",
          color: "rgba(255,255,255,0.95)",
          fontWeight: 900, fontSize: 14, letterSpacing: "0.18em",
          textAlign: "center",
          transform: "translateY(-50%) rotate(-12deg)",
          transformOrigin: "center",
          textShadow: "0 1px 2px rgba(0,0,0,0.2)"
        }}>
          達成済
        </div>
      </div>
    )}
  </div>
);

const StampRallySection = ({ event }) => {
  const allStamps = event.stamp_entries || [];
  const phases = event.stamp_rally_phases || [];

  // 2件以上のときのみタブを表示。デフォルトは「今」を含む期間 → 無ければ先頭。
  const defaultIdx = (() => {
    if (phases.length < 2) return 0;
    const idx = phases.findIndex(phaseContainsNow);
    return idx >= 0 ? idx : 0;
  })();
  const [activePhaseIdx, setActivePhaseIdx] = useState(defaultIdx);

  // 期間が 0 件 → 全スタンプ。1 件以上 → 該当期間で絞り込み。
  const visibleStamps = (() => {
    if (phases.length === 0) return allStamps;
    const phase = phases[Math.min(activePhaseIdx, phases.length - 1)];
    return allStamps.filter((s) => isEntryInPhase(s, phase));
  })();

  const ticketCount = phases.length === 0
    ? (event.ticket_count || 0)
    : computeTickets(visibleStamps);

  // 種別ごとに created_at 昇順で並べ、perTicket 単位の成立口と残りの未成立分に分割。
  const groupBlocks = STAMP_TYPE_DEFS.map((def) => {
    const sorted = visibleStamps
      .filter((s) => s.action_type === def.type)
      .sort((a, b) => new Date(a.created_at) - new Date(b.created_at));
    const completedCount = Math.floor(sorted.length / def.perTicket);
    const completed = Array.from({ length: completedCount }, (_, i) =>
      sorted.slice(i * def.perTicket, (i + 1) * def.perTicket)
    );
    const inProgress = sorted.slice(completedCount * def.perTicket);
    return { ...def, completed, inProgress };
  });

  return (
    <div id="stamp-rally" style={{ background: "#fafaf9", padding: "24px 16px" }}>
      <div style={{ maxWidth: 720, margin: "0 auto" }}>
        <h2 style={{ fontSize: 18, fontWeight: 800, color: "#1c1917", margin: 0, marginBottom: 12 }}>
          🏅 スタンプラリー
        </h2>

        {event.stamp_rally_description && (
          <p style={{
            fontSize: 12, color: "#78716c", lineHeight: 1.7,
            whiteSpace: "pre-wrap", marginBottom: 16
          }}>
            {event.stamp_rally_description}
          </p>
        )}

        {phases.length >= 2 && (
          <div style={{
            background: "#fff", borderBottom: "1px solid #e7e5e4",
            marginBottom: 16, marginLeft: -16, marginRight: -16
          }}>
            <div style={{ display: "flex" }}>
              {phases.map((phase, i) => {
                const isActive = i === activePhaseIdx;
                const startLbl = formatMonthDay(phase.start_on);
                const endLbl = formatMonthDay(phase.end_on);
                const rangeLbl = startLbl && endLbl
                  ? `${startLbl}〜${endLbl}`
                  : (startLbl ? `${startLbl}〜` : (endLbl ? `〜${endLbl}` : ""));
                return (
                  <button
                    key={i}
                    type="button"
                    onClick={() => setActivePhaseIdx(i)}
                    style={{
                      flex: 1, padding: "10px 8px", background: "none", border: "none",
                      borderBottom: `3px solid ${isActive ? "#CA4E0E" : "transparent"}`,
                      color: isActive ? "#CA4E0E" : "#a8a29e",
                      fontWeight: isActive ? 700 : 500,
                      cursor: "pointer", fontSize: 13, lineHeight: 1.35,
                      textAlign: "center", transition: "all 0.2s"
                    }}
                  >
                    <div>{phase.title || `第${i + 1}弾`}</div>
                    {rangeLbl && (
                      <div style={{ fontSize: 11, fontWeight: 500, marginTop: 2, opacity: 0.85 }}>
                        {rangeLbl}
                      </div>
                    )}
                  </button>
                );
              })}
            </div>
          </div>
        )}

        <div style={{
          display: "flex", alignItems: "baseline", gap: 4,
          marginBottom: 20
        }}>
          <span style={{ fontSize: 13, color: "#78716c" }}>合計</span>
          <span style={{ fontSize: 28, fontWeight: 800, color: "#488479" }}>{ticketCount}</span>
          <span style={{ fontSize: 13, color: "#78716c" }}>口</span>
        </div>

        {/* 未成立グループ: 4種別を常に1ブロックずつ表示 */}
        {groupBlocks.map((g) => (
          <TicketBlock
            key={`pending-${g.type}`}
            label={g.label}
            perTicket={g.perTicket}
            filledStamps={g.inProgress}
          />
        ))}

        {/* 成立済グループ: 種別固定順 × 同種別内 created_at 昇順。0件なら出さない */}
        {groupBlocks.flatMap((g) =>
          g.completed.map((stamps, idx) => (
            <TicketBlock
              key={`completed-${g.type}-${idx}`}
              label={g.label}
              perTicket={g.perTicket}
              filledStamps={stamps}
              completed
            />
          ))
        )}
      </div>
    </div>
  );
};

const EventShow = ({ props }) => {
  const { event, line_login_url, add_friend_url, current_event_path, current_event_line_user_id } = props;
  const [activeTab, setActiveTab] = useState("all");
  const [shareOpen, setShareOpen] = useState(false);

  // ログイン済みユーザだけ ?ru=<event_line_user_id> 付きの URL をシェアさせる。
  // 既存の rs パラメータは紛らわしいので落とす (シェアの主体はあくまでユーザ)。
  const shareUrl = (() => {
    if (!current_event_path) return "";
    try {
      const u = new URL(current_event_path);
      u.searchParams.delete("rs");
      if (current_event_line_user_id) {
        u.searchParams.set("ru", String(current_event_line_user_id));
      } else {
        u.searchParams.delete("ru");
      }
      return u.toString();
    } catch (e) {
      return current_event_path;
    }
  })();

  const seminars = event.contents ? event.contents.filter(c => c.content_type === "seminar") : [];
  const booths = event.contents ? event.contents.filter(c => c.content_type === "booth") : [];

  const visibleContents = activeTab === "seminar" ? seminars
    : activeTab === "booth" ? booths
    : (event.contents || []);

  return (
    <div style={{ minHeight: "100vh", background: "#fafaf9" }}>
      {/* Hero */}
      {(() => {
        // ヒーロー画像が未設定かつロゴ画像が設定されているときは、ロゴ中心レイアウト。
        const useLogoLayout = !event.hero_image_url && !!event.logo_image_url;
        // ヒーロー画像がない場合は背景色 #464342 に統一（ロゴ有無を問わず文字色は白）。
        const heroBackground = event.hero_image_url
          ? `url(${event.hero_image_url}) center/cover no-repeat`
          : "#464342";

        return (
          <div style={{
            background: heroBackground,
            color: "#fff", padding: "88px 20px 48px", position: "relative", overflow: "hidden"
          }}>
            {event.hero_image_url && (
              <div style={{ position: "absolute", top: 0, left: 0, right: 0, bottom: 0, background: "rgba(0,0,0,0.5)" }} />
            )}

            {event.is_participant && (
              <div style={{
                position: "absolute", top: 12, right: 12, zIndex: 2,
                display: "inline-flex", alignItems: "center", gap: 6,
                background: "rgba(255,255,255,0.18)", border: "1px solid rgba(255,255,255,0.45)",
                borderRadius: 20, padding: "6px 14px", fontSize: 12, fontWeight: 600, color: "#fff",
                backdropFilter: "blur(4px)", WebkitBackdropFilter: "blur(4px)"
              }}>
                <svg width="14" height="14" viewBox="0 0 20 20" fill="currentColor"><path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd"/></svg>
                参加登録済み
              </div>
            )}

            {useLogoLayout ? (
              <div style={{ maxWidth: 720, margin: "0 auto", position: "relative", zIndex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", minHeight: 220, textAlign: "center" }}>
                <img
                  src={event.logo_image_url}
                  alt={event.title}
                  style={{ maxWidth: "min(560px, 92%)", maxHeight: 300, width: "auto", height: "auto", objectFit: "contain", display: "block", margin: "0 auto" }}
                />

                {(() => {
                  const start = formatJaDateWithWeekday(event.start_at);
                  const end = formatJaDateWithWeekday(event.end_at);
                  if (!start && !end) return null;
                  return (
                    <div style={{ display: "flex", alignItems: "center", justifyContent: "center", flexWrap: "wrap", gap: 10, marginTop: 28, fontSize: 22, fontWeight: 700, color: "#fff", letterSpacing: "0.02em" }}>
                      <svg width="22" height="22" viewBox="0 0 20 20" fill="currentColor" style={{ opacity: 0.9 }}><path fillRule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clipRule="evenodd"/></svg>
                      <span>
                        {start}
                        {start && end && <span style={{ margin: "0 8px" }}>〜</span>}
                        {end}
                      </span>
                    </div>
                  );
                })()}

                {event.description && (
                  <p style={{ fontSize: 14, lineHeight: 1.8, color: "rgba(255,255,255,0.85)", whiteSpace: "pre-wrap", marginTop: 16, maxWidth: 560 }}>
                    {event.description}
                  </p>
                )}

                {!event.is_participant && !event.ended && line_login_url && (
                  <div style={{ marginTop: 24 }}>
                    <EventLineLoginLink loginUrl={line_login_url} btnText="LINEで参加登録する" />
                  </div>
                )}
              </div>
            ) : (
              <div style={{ maxWidth: 720, margin: "0 auto", position: "relative", zIndex: 1 }}>
                <h1 style={{ fontSize: 28, fontWeight: 800, marginBottom: 12, lineHeight: 1.3, letterSpacing: "-0.02em" }}>
                  {event.title}
                </h1>

                {(() => {
                  const start = formatJaDateWithWeekday(event.start_at);
                  const end = formatJaDateWithWeekday(event.end_at);
                  if (!start && !end) return null;
                  return (
                    <div style={{ display: "flex", alignItems: "center", flexWrap: "wrap", gap: 10, marginBottom: 20, fontSize: 22, fontWeight: 700, color: "#fff", letterSpacing: "0.02em" }}>
                      <svg width="22" height="22" viewBox="0 0 20 20" fill="currentColor" style={{ opacity: 0.9 }}><path fillRule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clipRule="evenodd"/></svg>
                      <span>
                        {start}
                        {start && end && <span style={{ margin: "0 8px" }}>〜</span>}
                        {end}
                      </span>
                    </div>
                  );
                })()}

                {event.description && (
                  <p style={{ fontSize: 14, lineHeight: 1.8, color: "rgba(255,255,255,0.85)", whiteSpace: "pre-wrap", marginBottom: 24 }}>
                    {event.description}
                  </p>
                )}

                {!event.is_participant && !event.ended && line_login_url && (
                  <EventLineLoginLink loginUrl={line_login_url} btnText="LINEで参加登録する" />
                )}
              </div>
            )}
          </div>
        );
      })()}

      {/* Status banner (below MV) — 開催期間自体はMV内に表示 */}
      {(event.not_started || event.ended) && (
        <div style={{ background: "#fafaf9", borderBottom: "1px solid #e7e5e4", padding: "24px 20px" }}>
          <div style={{ maxWidth: 720, margin: "0 auto" }}>
            {event.not_started && (
              <div style={{
                border: "2px solid #CA4E0E", background: "#fff",
                padding: "18px 20px", textAlign: "center",
                fontWeight: 800, fontSize: 16, color: "#CA4E0E",
                letterSpacing: "0.02em"
              }}>
                イベント開始までお待ちください
              </div>
            )}

            {event.ended && (
              <div style={{
                border: "2px solid #57534e", background: "#fff",
                padding: "18px 20px", textAlign: "center",
                fontWeight: 800, fontSize: 16, color: "#44403c",
                letterSpacing: "0.02em"
              }}>
                イベントは終了しました
              </div>
            )}
          </div>
        </div>
      )}

      {/* 開催終了後はMVと状態バナー以外は非表示 */}
      {!event.ended && (
        <>
          {/* Share bar */}
          <div style={{ background: "#fff", borderBottom: "1px solid #e7e5e4", padding: "12px 20px" }}>
            <div style={{ maxWidth: 720, margin: "0 auto", display: "flex", alignItems: "center", justifyContent: "center", gap: 12 }}>
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
              {event.is_participant && (
                <button
                  onClick={() => {
                    const el = document.getElementById("stamp-rally");
                    if (el) el.scrollIntoView({ behavior: "smooth" });
                  }}
                  style={{
                    display: "inline-flex", alignItems: "center", gap: 6,
                    padding: "8px 18px", border: "1px solid #d6d3d1", borderRadius: 20,
                    background: "#fff", cursor: "pointer", fontSize: 13, fontWeight: 600, color: "#44403c"
                  }}
                >
                  <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor"><path fillRule="evenodd" d="M6.267 3.455a3.066 3.066 0 001.745-.723 3.066 3.066 0 013.976 0 3.066 3.066 0 001.745.723 3.066 3.066 0 012.812 2.812c.051.643.304 1.254.723 1.745a3.066 3.066 0 010 3.976 3.066 3.066 0 00-.723 1.745 3.066 3.066 0 01-2.812 2.812 3.066 3.066 0 00-1.745.723 3.066 3.066 0 01-3.976 0 3.066 3.066 0 00-1.745-.723 3.066 3.066 0 01-2.812-2.812 3.066 3.066 0 00-.723-1.745 3.066 3.066 0 010-3.976 3.066 3.066 0 00.723-1.745 3.066 3.066 0 012.812-2.812zm7.44 5.252a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd"/></svg>
                  スタンプラリー
                </button>
              )}
            </div>
          </div>

          {/* Recommendations Carousel */}
          {event.is_participant && (event.recommended_content_ids || []).length > 0 && (() => {
            const recContents = (event.recommended_content_ids || [])
              .map(id => (event.contents || []).find(c => c.id === id))
              .filter(Boolean);
            if (recContents.length === 0) return null;
            return (
              <RecommendationCarousel
                contents={recContents}
                eventSlug={event.slug}
                disableLinks={event.not_started}
                eventLogoUrl={event.logo_image_url}
                isParticipant={event.is_participant}
                canPreviewAll={event.can_preview_all}
                previewableContentIds={event.previewable_content_ids || []}
              />
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
                      borderBottom: `3px solid ${activeTab === val ? "#488479" : "transparent"}`,
                      color: activeTab === val ? "#488479" : "#a8a29e",
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
              (() => {
                const previewableSet = new Set(event.previewable_content_ids || []);
                return visibleContents.map(content => (
                  <ContentCard
                    key={content.id}
                    content={content}
                    eventSlug={event.slug}
                    isParticipant={event.is_participant}
                    lineLoginUrl={line_login_url}
                    disableLinks={event.not_started}
                    previewable={event.can_preview_all || previewableSet.has(content.id)}
                    eventLogoUrl={event.logo_image_url}
                  />
                ));
              })()
            )}
          </div>

          {/* Stamp Rally */}
          {event.is_participant && (
            <StampRallySection event={event} />
          )}
        </>
      )}

      {/* Footer CTA (開催終了後は非表示) */}
      {!event.is_participant && !event.ended && line_login_url && (
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
        shareUrl={shareUrl}
      />
    </div>
  );
};

export default EventShow;
