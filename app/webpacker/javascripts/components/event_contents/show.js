"use strict"

import React, { useState, useRef, useEffect } from "react";

const getEmbedUrl = (url) => {
  if (!url) return null;
  // YouTube
  const ytMatch = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]+)/);
  if (ytMatch) return `https://www.youtube.com/embed/${ytMatch[1]}?autoplay=1&rel=0`;
  // Google Drive
  const driveMatch = url.match(/\/file\/d\/([a-zA-Z0-9_-]+)/);
  if (driveMatch) return `https://drive.google.com/file/d/${driveMatch[1]}/preview`;
  return url;
};

const VideoPlayer = ({ preAdUrl, contentUrl, postAdUrl, onComplete }) => {
  const [phase, setPhase] = useState(preAdUrl ? "pre_ad" : "main");
  const [iframeKey, setIframeKey] = useState(0);

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
    <div style={{ background: "#000", borderRadius: 8, overflow: "hidden" }}>
      <div style={{ padding: "6px 12px", background: "rgba(255,255,255,0.1)", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <span style={{ color: "#fff", fontSize: 12 }}>{phaseLabel}</span>
        <button onClick={nextPhase} style={{ background: "rgba(255,255,255,0.2)", color: "#fff", border: "none", borderRadius: 4, padding: "4px 10px", cursor: "pointer", fontSize: 12 }}>
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

const PDFCarousel = ({ images, onlineServiceUrl }) => {
  const [current, setCurrent] = useState(0);
  const total = images.length;

  if (total === 0) return null;

  return (
    <div style={{ background: "#000", borderRadius: 8, overflow: "hidden" }}>
      <div style={{ position: "relative" }}>
        <img src={images[current].url} style={{ width: "100%", maxHeight: 400, objectFit: "contain", background: "#000" }} />
        {total > 1 && (
          <>
            <button
              onClick={() => setCurrent(i => (i - 1 + total) % total)}
              style={{ position: "absolute", left: 8, top: "50%", transform: "translateY(-50%)", background: "rgba(0,0,0,0.5)", color: "#fff", border: "none", borderRadius: "50%", width: 36, height: 36, cursor: "pointer", fontSize: 18 }}
            >‹</button>
            <button
              onClick={() => setCurrent(i => (i + 1) % total)}
              style={{ position: "absolute", right: 8, top: "50%", transform: "translateY(-50%)", background: "rgba(0,0,0,0.5)", color: "#fff", border: "none", borderRadius: "50%", width: 36, height: 36, cursor: "pointer", fontSize: 18 }}
            >›</button>
          </>
        )}
        <div style={{ position: "absolute", bottom: 8, left: "50%", transform: "translateX(-50%)", display: "flex", gap: 4 }}>
          {images.map((_, i) => (
            <div key={i} onClick={() => setCurrent(i)} style={{ width: 8, height: 8, borderRadius: "50%", background: i === current ? "#fff" : "rgba(255,255,255,0.4)", cursor: "pointer" }} />
          ))}
        </div>
      </div>
      <div style={{ padding: "8px 12px", display: "flex", justifyContent: "space-between", alignItems: "center", background: "rgba(255,255,255,0.05)" }}>
        <span style={{ color: "#fff", fontSize: 12 }}>{current + 1} / {total}</span>
        {onlineServiceUrl && (
          <span style={{ color: "rgba(255,255,255,0.7)", fontSize: 11 }}>続きはダウンロードで確認できます</span>
        )}
      </div>
    </div>
  );
};

const UpsellSection = ({ content, startUsageUrl, upsellConsultationUrl, monitorApplyUrl }) => {
  const [consultationStatus, setConsultationStatus] = useState(content.consultation_status);
  const [monitorApplied, setMonitorApplied] = useState(content.has_monitor_applied);
  const [isLoading, setIsLoading] = useState(false);

  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

  const handleConsultation = async () => {
    if (consultationStatus || isLoading) return;
    setIsLoading(true);
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
    <div style={{ marginTop: 24 }}>
      {content.upsell_booking_enabled && (
        <div style={{ background: "#f0fff4", border: "1px solid #9ae6b4", borderRadius: 12, padding: 16, marginBottom: 12 }}>
          <h4 style={{ fontWeight: "bold", fontSize: 15, marginBottom: 8 }}>💬 無料相談を予約する</h4>
          {consultationStatus ? (
            <div style={{ textAlign: "center", color: "#2f855a", padding: 12, fontWeight: "bold" }}>
              {consultationStatus === "waitlist" ? "キャンセル待ちを承りました" : "予約済み"}
            </div>
          ) : (
            <button
              onClick={handleConsultation}
              disabled={isLoading}
              style={{ width: "100%", padding: "12px", background: "#276749", color: "#fff", border: "none", borderRadius: 8, fontSize: 15, fontWeight: "bold", cursor: "pointer" }}
            >
              {isLoading ? "処理中..." : "無料相談を予約する"}
            </button>
          )}
        </div>
      )}

      {content.monitor_enabled && (
        <div style={{ background: "#fffaf0", border: "1px solid #fbd38d", borderRadius: 12, padding: 16 }}>
          <h4 style={{ fontWeight: "bold", fontSize: 15, marginBottom: 4 }}>⭐ モニターに応募する</h4>
          {content.monitor_name && <p style={{ fontSize: 13, color: "#666", marginBottom: 4 }}>サービス: {content.monitor_name}</p>}
          {content.monitor_price !== null && <p style={{ fontSize: 13, color: "#e53e3e", marginBottom: 8 }}>モニター金額: {content.monitor_price.toLocaleString()}円</p>}
          {monitorApplied ? (
            <div style={{ textAlign: "center", color: "#744210", padding: 12, fontWeight: "bold" }}>応募済みです</div>
          ) : (
            <button
              onClick={handleMonitorApply}
              disabled={isLoading}
              style={{ width: "100%", padding: "12px", background: "#c05621", color: "#fff", border: "none", borderRadius: 8, fontSize: 15, fontWeight: "bold", cursor: "pointer" }}
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
  const { event_content, event_slug, event_title, start_usage_url, upsell_consultation_url, monitor_apply_url, back_url } = props;
  const [hasStarted, setHasStarted] = useState(event_content.has_started_usage);
  const [isStarting, setIsStarting] = useState(false);

  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

  const handleStartUsage = async () => {
    if (isStarting || hasStarted) return;
    setIsStarting(true);
    const res = await fetch(start_usage_url, { method: "POST", headers: { "X-CSRF-Token": csrfToken } });
    const data = await res.json();
    if (data.success) setHasStarted(true);
    setIsStarting(false);
  };

  const canStart = event_content.started && !event_content.ended && !event_content.capacity_full;

  return (
    <div style={{ minHeight: "100vh", background: "#f7f8fc" }}>
      {/* Header */}
      <div style={{ background: "#1a1a2e", color: "#fff", padding: "16px 20px", display: "flex", alignItems: "center", gap: 12 }}>
        <a href={back_url} style={{ color: "#fff", textDecoration: "none", fontSize: 20 }}>‹</a>
        <div>
          <div style={{ fontSize: 12, opacity: 0.7 }}>{event_title}</div>
          <h1 style={{ fontSize: 18, fontWeight: "bold", margin: 0 }}>{event_content.title}</h1>
        </div>
      </div>

      <div style={{ maxWidth: 800, margin: "0 auto", padding: "16px" }}>
        {/* Thumbnail / Content Area */}
        {!hasStarted ? (
          <div style={{ borderRadius: 12, overflow: "hidden", marginBottom: 16 }}>
            {event_content.thumbnail_url ? (
              <img src={event_content.thumbnail_url} style={{ width: "100%", maxHeight: 300, objectFit: "cover" }} />
            ) : (
              <div style={{ background: "#2d3748", height: 200, display: "flex", alignItems: "center", justifyContent: "center", color: "#fff", fontSize: 48 }}>
                {event_content.content_type === "seminar" ? "🎬" : "📄"}
              </div>
            )}
          </div>
        ) : event_content.content_type === "seminar" ? (
          <div style={{ marginBottom: 16 }}>
            <VideoPlayer
              preAdUrl={event_content.pre_ad_video_url}
              contentUrl={event_content.online_service_registration_url}
              postAdUrl={event_content.post_ad_video_url}
            />
            {event_content.direct_download_url && (
              <a
                href={event_content.direct_download_url}
                target="_blank"
                rel="noopener noreferrer"
                style={{ display: "block", marginTop: 12, padding: "10px 20px", background: "#3182ce", color: "#fff", borderRadius: 8, textAlign: "center", textDecoration: "none", fontWeight: "bold" }}
              >
                📥 資料をダウンロード
              </a>
            )}
          </div>
        ) : (
          <div style={{ marginBottom: 16 }}>
            <PDFCarousel
              images={event_content.slide_images || []}
              onlineServiceUrl={event_content.online_service_registration_url}
            />
          </div>
        )}

        {/* Start Usage Button */}
        {!hasStarted && event_content.is_participant && canStart && (
          <button
            onClick={handleStartUsage}
            disabled={isStarting}
            style={{ width: "100%", padding: "14px", background: "#00b900", color: "#fff", border: "none", borderRadius: 8, fontSize: 16, fontWeight: "bold", cursor: "pointer", marginBottom: 16 }}
          >
            {isStarting ? "..." : event_content.content_type === "seminar" ? "セミナーを視聴する" : "出展ブースに入る"}
          </button>
        )}

        {event_content.ended && (
          <div style={{ background: "#fed7d7", color: "#c53030", padding: "12px 16px", borderRadius: 8, textAlign: "center", marginBottom: 16, fontWeight: "bold" }}>
            このコンテンツは終了しました
          </div>
        )}

        {!event_content.started && (
          <div style={{ background: "#fefcbf", color: "#744210", padding: "12px 16px", borderRadius: 8, textAlign: "center", marginBottom: 16 }}>
            サービス開始前です。開始をお待ちください。
          </div>
        )}

        {/* Introduction */}
        {event_content.introduction && (
          <div style={{ background: "#fff", borderRadius: 12, padding: 16, marginBottom: 16, border: "1px solid #e2e8f0" }}>
            <h3 style={{ fontWeight: "bold", fontSize: 15, marginBottom: 8 }}>紹介文</h3>
            <p style={{ color: "#4a5568", lineHeight: 1.7, whiteSpace: "pre-wrap" }}>{event_content.introduction}</p>
          </div>
        )}

        {/* Description */}
        {event_content.description && (
          <div style={{ background: "#fff", borderRadius: 12, padding: 16, marginBottom: 16, border: "1px solid #e2e8f0" }}>
            <h3 style={{ fontWeight: "bold", fontSize: 15, marginBottom: 8 }}>説明</h3>
            <p style={{ color: "#4a5568", lineHeight: 1.7, whiteSpace: "pre-wrap" }}>{event_content.description}</p>
          </div>
        )}

        {/* Exhibitor Info */}
        {event_content.exhibitor_staff && (
          <div style={{ background: "#fff", borderRadius: 12, padding: 16, marginBottom: 16, border: "1px solid #e2e8f0" }}>
            <h3 style={{ fontWeight: "bold", fontSize: 15, marginBottom: 12 }}>出展者情報</h3>
            <div style={{ display: "flex", gap: 12, alignItems: "flex-start" }}>
              {event_content.exhibitor_staff.picture_url && (
                <img src={event_content.exhibitor_staff.picture_url} style={{ width: 72, height: 72, borderRadius: "50%", objectFit: "cover", flexShrink: 0 }} />
              )}
              <div>
                {event_content.exhibitor_staff.position && (
                  <div style={{ fontSize: 12, color: "#888", marginBottom: 2 }}>{event_content.exhibitor_staff.position}</div>
                )}
                <div style={{ fontWeight: "bold", fontSize: 15 }}>{event_content.exhibitor_staff.name}</div>
                {event_content.exhibitor_staff.introduction && (
                  <p style={{ fontSize: 13, color: "#555", marginTop: 6, lineHeight: 1.6, whiteSpace: "pre-wrap" }}>{event_content.exhibitor_staff.introduction}</p>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Share */}
        <div style={{ background: "#fff", borderRadius: 12, padding: 16, marginBottom: 16, border: "1px solid #e2e8f0" }}>
          <h3 style={{ fontWeight: "bold", fontSize: 15, marginBottom: 8 }}>シェア</h3>
          <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
            {event_content.thumbnail_url && (
              <a href={event_content.thumbnail_url} download style={{ padding: "8px 16px", background: "#718096", color: "#fff", borderRadius: 20, fontSize: 13, textDecoration: "none" }}>
                📥 サムネをDL
              </a>
            )}
            <a href={`https://twitter.com/intent/tweet?text=${encodeURIComponent(event_content.title)}&url=${encodeURIComponent(window.location.href)}`} target="_blank" rel="noopener noreferrer"
              style={{ padding: "8px 16px", background: "#000", color: "#fff", borderRadius: 20, fontSize: 13, textDecoration: "none" }}>X</a>
            <a href={`https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(window.location.href)}`} target="_blank" rel="noopener noreferrer"
              style={{ padding: "8px 16px", background: "#1877f2", color: "#fff", borderRadius: 20, fontSize: 13, textDecoration: "none" }}>Facebook</a>
          </div>
        </div>

        {/* Upsell */}
        {(event_content.upsell_booking_enabled || event_content.monitor_enabled) && hasStarted && (
          <UpsellSection
            content={event_content}
            startUsageUrl={start_usage_url}
            upsellConsultationUrl={upsell_consultation_url}
            monitorApplyUrl={monitor_apply_url}
          />
        )}
      </div>
    </div>
  );
};

export default EventContentShow;
