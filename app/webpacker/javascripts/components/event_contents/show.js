"use strict"

import React, { useState, useRef, useEffect } from "react";

const getEmbedUrl = (url) => {
  if (!url) return null;
  const ytMatch = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]+)/);
  if (ytMatch) return `https://www.youtube.com/embed/${ytMatch[1]}?autoplay=1&rel=0`;
  const driveMatch = url.match(/\/file\/d\/([a-zA-Z0-9_-]+)/);
  if (driveMatch) return `https://drive.google.com/file/d/${driveMatch[1]}/preview`;
  return url;
};

const LineLoginForm = ({ loginUrl, btnText, style }) => {
  if (!loginUrl) return null;

  const url = new URL(loginUrl, window.location.origin);
  const params = Object.fromEntries(url.searchParams);

  return (
    <form method="post" action={url.pathname} style={{ display: "inline-block", ...style }}>
      <input type="hidden" name="authenticity_token" value={document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')} />
      {Object.entries(params).map(([key, value]) => (
        <input key={key} type="hidden" name={key} value={value} />
      ))}
      <button
        type="submit"
        style={{
          display: "inline-flex", alignItems: "center", gap: 8,
          padding: "14px 28px", background: "#06c755", color: "#fff",
          borderRadius: 30, fontSize: 15, fontWeight: "bold",
          border: "none", cursor: "pointer", boxShadow: "0 4px 14px rgba(6,199,85,0.4)",
          width: "100%", justifyContent: "center"
        }}
      >
        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M19.365 9.863c.349 0 .63.285.63.631 0 .345-.281.63-.63.63H17.61v1.125h1.755c.349 0 .63.283.63.63 0 .344-.281.629-.63.629h-2.386c-.345 0-.627-.285-.627-.629V8.108c0-.345.282-.63.63-.63h2.386c.346 0 .627.285.627.63 0 .349-.281.63-.63.63H17.61v1.125h1.755zm-3.855 3.016c0 .27-.174.51-.432.596-.064.021-.133.031-.199.031-.211 0-.391-.09-.51-.25l-2.443-3.317v2.94c0 .344-.279.629-.631.629-.346 0-.626-.285-.626-.629V8.108c0-.27.173-.51.43-.595.06-.023.136-.033.194-.033.195 0 .375.104.495.254l2.462 3.33V8.108c0-.345.282-.63.63-.63.345 0 .63.285.63.63v4.771zm-5.741 0c0 .344-.282.629-.631.629-.345 0-.627-.285-.627-.629V8.108c0-.345.282-.63.63-.63.346 0 .628.285.628.63v4.771zm-2.466.629H4.917c-.345 0-.63-.285-.63-.629V8.108c0-.345.285-.63.63-.63.348 0 .63.285.63.63v4.141h1.756c.348 0 .629.283.629.63 0 .344-.282.629-.629.629M24 10.314C24 4.943 18.615.572 12 .572S0 4.943 0 10.314c0 4.811 4.27 8.842 10.035 9.608.391.082.923.258 1.058.59.12.301.079.766.038 1.08l-.164 1.02c-.045.301-.24 1.186 1.049.645 1.291-.539 6.916-4.078 9.436-6.975C23.176 14.393 24 12.458 24 10.314"/></svg>
        {btnText}
      </button>
    </form>
  );
};

const ShareButtons = ({ title }) => {
  const encodedUrl = encodeURIComponent(window.location.href);
  const encodedTitle = encodeURIComponent(title);

  return (
    <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
      <a
        href={`https://www.facebook.com/sharer/sharer.php?u=${encodedUrl}`}
        target="_blank" rel="noopener noreferrer"
        style={{ width: 36, height: 36, borderRadius: "50%", background: "#1877f2", color: "#fff", display: "flex", alignItems: "center", justifyContent: "center", textDecoration: "none", fontSize: 16 }}
      >
        <i className="fab fa-facebook-f"></i>
      </a>
      <a
        href={`https://twitter.com/intent/tweet?text=${encodedTitle}&url=${encodedUrl}`}
        target="_blank" rel="noopener noreferrer"
        style={{ width: 36, height: 36, borderRadius: "50%", background: "#000", color: "#fff", display: "flex", alignItems: "center", justifyContent: "center", textDecoration: "none", fontSize: 16 }}
      >
        <i className="fab fa-x-twitter"></i>
      </a>
      <a
        href={`https://www.instagram.com/`}
        target="_blank" rel="noopener noreferrer"
        style={{ width: 36, height: 36, borderRadius: "50%", background: "linear-gradient(45deg, #f09433, #e6683c, #dc2743, #cc2366, #bc1888)", color: "#fff", display: "flex", alignItems: "center", justifyContent: "center", textDecoration: "none", fontSize: 16 }}
      >
        <i className="fab fa-instagram"></i>
      </a>
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
    <div style={{ background: "#000", borderRadius: 12, overflow: "hidden" }}>
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

const PDFCarousel = ({ images, onlineServiceUrl }) => {
  const [current, setCurrent] = useState(0);
  const total = images.length;

  if (total === 0) return null;

  return (
    <div style={{ background: "#000", borderRadius: 12, overflow: "hidden" }}>
      <div style={{ position: "relative" }}>
        <img src={images[current].url} style={{ width: "100%", maxHeight: 400, objectFit: "contain", background: "#000", display: "block" }} />
        {total > 1 && (
          <>
            <button
              onClick={() => setCurrent(i => (i - 1 + total) % total)}
              style={{ position: "absolute", left: 8, top: "50%", transform: "translateY(-50%)", background: "rgba(0,0,0,0.5)", color: "#fff", border: "none", borderRadius: "50%", width: 40, height: 40, cursor: "pointer", fontSize: 20 }}
            >‹</button>
            <button
              onClick={() => setCurrent(i => (i + 1) % total)}
              style={{ position: "absolute", right: 8, top: "50%", transform: "translateY(-50%)", background: "rgba(0,0,0,0.5)", color: "#fff", border: "none", borderRadius: "50%", width: 40, height: 40, cursor: "pointer", fontSize: 20 }}
            >›</button>
          </>
        )}
      </div>
      <div style={{ padding: "10px 14px", display: "flex", justifyContent: "space-between", alignItems: "center", background: "rgba(255,255,255,0.05)" }}>
        <div style={{ display: "flex", gap: 5 }}>
          {images.map((_, i) => (
            <div key={i} onClick={() => setCurrent(i)} style={{ width: 8, height: 8, borderRadius: "50%", background: i === current ? "#fff" : "rgba(255,255,255,0.3)", cursor: "pointer" }} />
          ))}
        </div>
        <span style={{ color: "rgba(255,255,255,0.6)", fontSize: 12 }}>{current + 1} / {total}</span>
      </div>
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
        <div style={{ background: "#f0fdf4", border: "1px solid #86efac", borderRadius: 16, padding: "20px" }}>
          <h4 style={{ fontWeight: 700, fontSize: 15, marginBottom: 10, color: "#166534" }}>無料相談を予約する</h4>
          {consultationStatus ? (
            <div style={{ textAlign: "center", color: "#166534", padding: 12, fontWeight: 700, fontSize: 14 }}>
              {consultationStatus === "waitlist" ? "キャンセル待ちを承りました" : "予約済みです"}
            </div>
          ) : (
            <button
              onClick={handleConsultation}
              disabled={isLoading}
              style={{ width: "100%", padding: "12px", background: "#16a34a", color: "#fff", border: "none", borderRadius: 10, fontSize: 14, fontWeight: 700, cursor: "pointer" }}
            >
              {isLoading ? "処理中..." : "無料相談を予約する"}
            </button>
          )}
        </div>
      )}

      {content.monitor_enabled && (
        <div style={{ background: "#fffbeb", border: "1px solid #fcd34d", borderRadius: 16, padding: "20px" }}>
          <h4 style={{ fontWeight: 700, fontSize: 15, marginBottom: 6, color: "#92400e" }}>モニターに応募する</h4>
          {content.monitor_name && <p style={{ fontSize: 13, color: "#78716c", marginBottom: 4 }}>サービス: {content.monitor_name}</p>}
          {content.monitor_price !== null && <p style={{ fontSize: 13, color: "#dc2626", marginBottom: 10, fontWeight: 600 }}>モニター金額: {content.monitor_price.toLocaleString()}円</p>}
          {monitorApplied ? (
            <div style={{ textAlign: "center", color: "#92400e", padding: 12, fontWeight: 700, fontSize: 14 }}>応募済みです</div>
          ) : (
            <button
              onClick={handleMonitorApply}
              disabled={isLoading}
              style={{ width: "100%", padding: "12px", background: "#d97706", color: "#fff", border: "none", borderRadius: 10, fontSize: 14, fontWeight: 700, cursor: "pointer" }}
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

  const ctaLabel = event_content.content_type === "seminar" ? "セミナーを視聴する" : "出展ブースに入る";
  const typeColor = event_content.content_type === "seminar" ? "#4f46e5" : "#0ea5e9";

  return (
    <div style={{ minHeight: "100vh", background: "#f8fafc" }}>
      {/* Header */}
      <div style={{ background: "#0f172a", color: "#fff", padding: "14px 20px", display: "flex", alignItems: "center", gap: 14, position: "sticky", top: 0, zIndex: 20 }}>
        <a href={back_url} style={{ color: "#fff", textDecoration: "none", fontSize: 22, lineHeight: 1, flexShrink: 0 }}>‹</a>
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
                style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 8, marginTop: 12, padding: "12px 20px", background: "#3b82f6", color: "#fff", borderRadius: 10, textDecoration: "none", fontWeight: 700, fontSize: 14 }}
              >
                <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor"><path fillRule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clipRule="evenodd"/></svg>
                資料をダウンロード
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
                style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 8, marginTop: 12, padding: "12px 20px", background: "#0ea5e9", color: "#fff", borderRadius: 10, textDecoration: "none", fontWeight: 700, fontSize: 14 }}
              >
                <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v3.586L7.707 9.293a1 1 0 00-1.414 1.414l3 3a1 1 0 001.414 0l3-3a1 1 0 00-1.414-1.414L11 10.586V7z" clipRule="evenodd"/></svg>
                出展企業のサービスページへ
              </a>
            )}
          </div>
        ) : (
          <div style={{ borderRadius: 16, overflow: "hidden", marginBottom: 20 }}>
            {event_content.thumbnail_url ? (
              <img src={event_content.thumbnail_url} style={{ width: "100%", maxHeight: 320, objectFit: "cover", display: "block" }} />
            ) : (
              <div style={{ height: 180, background: `linear-gradient(135deg, ${typeColor}, ${typeColor}cc)`, display: "flex", alignItems: "center", justifyContent: "center" }}>
                <span style={{ fontSize: 56 }}>{event_content.content_type === "seminar" ? "🎬" : "📄"}</span>
              </div>
            )}
          </div>
        )}

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
          <div style={{ background: "#fef2f2", border: "1px solid #fecaca", color: "#991b1b", padding: "12px 16px", borderRadius: 12, textAlign: "center", marginBottom: 16, fontWeight: 700, fontSize: 14 }}>
            このコンテンツは終了しました
          </div>
        )}

        {!event_content.started && !event_content.ended && (
          <div style={{ background: "#fffbeb", border: "1px solid #fde68a", color: "#92400e", padding: "12px 16px", borderRadius: 12, textAlign: "center", marginBottom: 16, fontSize: 14 }}>
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
              borderRadius: 12, fontSize: 16, fontWeight: 700,
              cursor: "pointer", boxShadow: `0 4px 14px ${typeColor}66`
            }}
          >
            {isStarting ? "..." : ctaLabel}
          </button>
        )}

        {/* LINE login CTA for non-participants */}
        {!isParticipant && line_login_url && (
          <div style={{ background: "#f0fdf4", border: "1px solid #bbf7d0", borderRadius: 16, padding: "24px 20px", marginBottom: 20, textAlign: "center" }}>
            <p style={{ fontSize: 14, color: "#166534", marginBottom: 14, fontWeight: 600 }}>
              参加登録してコンテンツを利用しましょう
            </p>
            <LineLoginForm loginUrl={line_login_url} btnText="LINEで参加登録する" />
          </div>
        )}

        {/* Introduction */}
        {event_content.introduction && (
          <div style={{ background: "#fff", borderRadius: 16, padding: "20px", marginBottom: 16, border: "1px solid #e5e7eb" }}>
            <h3 style={{ fontWeight: 700, fontSize: 15, marginBottom: 10, color: "#111827" }}>紹介文</h3>
            <p style={{ color: "#4b5563", lineHeight: 1.8, whiteSpace: "pre-wrap", fontSize: 14 }}>{event_content.introduction}</p>
          </div>
        )}

        {/* Description */}
        {event_content.description && (
          <div style={{ background: "#fff", borderRadius: 16, padding: "20px", marginBottom: 16, border: "1px solid #e5e7eb" }}>
            <h3 style={{ fontWeight: 700, fontSize: 15, marginBottom: 10, color: "#111827" }}>説明</h3>
            <p style={{ color: "#4b5563", lineHeight: 1.8, whiteSpace: "pre-wrap", fontSize: 14 }}>{event_content.description}</p>
          </div>
        )}

        {/* Speakers */}
        {(event_content.speakers || []).length > 0 && (
          <div style={{ background: "#fff", borderRadius: 16, padding: "20px", marginBottom: 16, border: "1px solid #e5e7eb" }}>
            <h3 style={{ fontWeight: 700, fontSize: 15, marginBottom: 14, color: "#111827" }}>出演者情報</h3>
            <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
              {event_content.speakers.map((speaker, idx) => (
                <div key={speaker.id || idx} style={{ display: "flex", gap: 14, alignItems: "flex-start" }}>
                  {speaker.profile_image_url ? (
                    <img src={speaker.profile_image_url} style={{ width: 72, height: 72, borderRadius: "50%", objectFit: "cover", flexShrink: 0, border: "3px solid #f3f4f6" }} />
                  ) : (
                    <div style={{ width: 72, height: 72, borderRadius: "50%", background: "#e5e7eb", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, fontSize: 28, color: "#9ca3af" }}>👤</div>
                  )}
                  <div>
                    {speaker.position_title && (
                      <div style={{ fontSize: 12, color: "#9ca3af", marginBottom: 2 }}>{speaker.position_title}</div>
                    )}
                    <div style={{ fontWeight: 700, fontSize: 16, color: "#111827", marginBottom: 6 }}>{speaker.name}</div>
                    {speaker.introduction && (
                      <p style={{ fontSize: 13, color: "#6b7280", lineHeight: 1.7, whiteSpace: "pre-wrap" }}>{speaker.introduction}</p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Exhibitor (fallback) */}
        {(event_content.speakers || []).length === 0 && event_content.exhibitor_staff && (
          <div style={{ background: "#fff", borderRadius: 16, padding: "20px", marginBottom: 16, border: "1px solid #e5e7eb" }}>
            <h3 style={{ fontWeight: 700, fontSize: 15, marginBottom: 14, color: "#111827" }}>出展者情報</h3>
            <div style={{ display: "flex", gap: 14, alignItems: "flex-start" }}>
              {event_content.exhibitor_staff.picture_url && (
                <img src={event_content.exhibitor_staff.picture_url} style={{ width: 72, height: 72, borderRadius: "50%", objectFit: "cover", flexShrink: 0, border: "3px solid #f3f4f6" }} />
              )}
              <div>
                {event_content.exhibitor_staff.position && (
                  <div style={{ fontSize: 12, color: "#9ca3af", marginBottom: 2 }}>{event_content.exhibitor_staff.position}</div>
                )}
                <div style={{ fontWeight: 700, fontSize: 16, color: "#111827", marginBottom: 6 }}>{event_content.exhibitor_staff.name}</div>
                {event_content.exhibitor_staff.introduction && (
                  <p style={{ fontSize: 13, color: "#6b7280", lineHeight: 1.7, whiteSpace: "pre-wrap" }}>{event_content.exhibitor_staff.introduction}</p>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Share */}
        <div style={{ background: "#fff", borderRadius: 16, padding: "20px", marginBottom: 16, border: "1px solid #e5e7eb" }}>
          <h3 style={{ fontWeight: 700, fontSize: 15, marginBottom: 10, color: "#111827" }}>シェア</h3>
          <ShareButtons title={event_content.title} />
        </div>

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
    </div>
  );
};

export default EventContentShow;
