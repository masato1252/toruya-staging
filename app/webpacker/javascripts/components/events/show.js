"use strict"

import React, { useState } from "react";
import { LineLoginBtn } from "shared/booking";

const ShareButtons = ({ title, url }) => {
  const encodedUrl = encodeURIComponent(url);
  const encodedTitle = encodeURIComponent(title);

  return (
    <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
      <a
        href={`https://www.facebook.com/sharer/sharer.php?u=${encodedUrl}`}
        target="_blank"
        rel="noopener noreferrer"
        style={{ width: 36, height: 36, borderRadius: "50%", background: "#1877f2", color: "#fff", display: "flex", alignItems: "center", justifyContent: "center", textDecoration: "none", fontSize: 16 }}
      >
        <i className="fab fa-facebook-f"></i>
      </a>
      <a
        href={`https://twitter.com/intent/tweet?text=${encodedTitle}&url=${encodedUrl}`}
        target="_blank"
        rel="noopener noreferrer"
        style={{ width: 36, height: 36, borderRadius: "50%", background: "#000", color: "#fff", display: "flex", alignItems: "center", justifyContent: "center", textDecoration: "none", fontSize: 16 }}
      >
        <i className="fab fa-x-twitter"></i>
      </a>
      <a
        href={`https://www.instagram.com/`}
        target="_blank"
        rel="noopener noreferrer"
        style={{ width: 36, height: 36, borderRadius: "50%", background: "linear-gradient(45deg, #f09433, #e6683c, #dc2743, #cc2366, #bc1888)", color: "#fff", display: "flex", alignItems: "center", justifyContent: "center", textDecoration: "none", fontSize: 16 }}
      >
        <i className="fab fa-instagram"></i>
      </a>
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
  if (content.ended) return <span style={{ background: "#6b7280", color: "#fff", fontSize: 11, padding: "3px 10px", borderRadius: 12, fontWeight: 600 }}>終了</span>;
  if (!content.started) return <span style={{ background: "#f59e0b", color: "#fff", fontSize: 11, padding: "3px 10px", borderRadius: 12, fontWeight: 600 }}>開始前</span>;
  if (content.capacity_full) return <span style={{ background: "#ef4444", color: "#fff", fontSize: 11, padding: "3px 10px", borderRadius: 12, fontWeight: 600 }}>満員</span>;
  return <span style={{ background: "#06c755", color: "#fff", fontSize: 11, padding: "3px 10px", borderRadius: 12, fontWeight: 600 }}>受付中</span>;
};

const ContentCard = ({ content, eventSlug, isParticipant, lineLoginUrl }) => {
  const ctaLabel = () => {
    if (content.content_type === "seminar") return "セミナーを視聴する";
    return "出展ブースに入る";
  };

  return (
    <div style={{
      background: "#fff", borderRadius: 16, overflow: "hidden",
      boxShadow: "0 1px 3px rgba(0,0,0,0.08), 0 4px 12px rgba(0,0,0,0.04)",
      transition: "box-shadow 0.2s",
      marginBottom: 20
    }}>
      <a href={`/${eventSlug}/event_contents/${content.id}`} style={{ textDecoration: "none", color: "inherit" }}>
        {content.thumbnail_url ? (
          <div style={{ position: "relative" }}>
            <img src={content.thumbnail_url} style={{ width: "100%", height: 200, objectFit: "cover", display: "block" }} />
            <div style={{ position: "absolute", top: 10, left: 10, display: "flex", gap: 6 }}>
              <StatusBadge content={content} />
              <span style={{
                background: content.content_type === "seminar" ? "rgba(79,70,229,0.9)" : "rgba(14,165,233,0.9)",
                color: "#fff", fontSize: 11, padding: "3px 10px", borderRadius: 12, fontWeight: 600
              }}>
                {content.content_type === "seminar" ? "セミナー" : "展示ブース"}
              </span>
            </div>
          </div>
        ) : (
          <div style={{ height: 120, background: content.content_type === "seminar" ? "linear-gradient(135deg, #4f46e5, #7c3aed)" : "linear-gradient(135deg, #0ea5e9, #06b6d4)", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <span style={{ fontSize: 40 }}>{content.content_type === "seminar" ? "🎬" : "📄"}</span>
          </div>
        )}
      </a>

      <div style={{ padding: "16px 20px" }}>
        <a href={`/${eventSlug}/event_contents/${content.id}`} style={{ textDecoration: "none", color: "inherit" }}>
          <h3 style={{ fontWeight: 700, fontSize: 17, marginBottom: 8, lineHeight: 1.4, color: "#111827" }}>{content.title}</h3>
        </a>

        {content.introduction && (
          <p style={{ color: "#6b7280", fontSize: 13, lineHeight: 1.7, marginBottom: 12, display: "-webkit-box", WebkitLineClamp: 3, WebkitBoxOrient: "vertical", overflow: "hidden" }}>
            {content.introduction}
          </p>
        )}

        {(content.speakers || []).length > 0 ? (
          <div style={{ marginBottom: 14, display: "flex", flexDirection: "column", gap: 6 }}>
            {content.speakers.map((speaker, idx) => (
              <div key={idx} style={{ display: "flex", alignItems: "center", gap: 10, padding: "8px 12px", background: "#f9fafb", borderRadius: 10 }}>
                {speaker.profile_image_url ? (
                  <img src={speaker.profile_image_url} style={{ width: 36, height: 36, borderRadius: "50%", objectFit: "cover", flexShrink: 0 }} />
                ) : (
                  <div style={{ width: 36, height: 36, borderRadius: "50%", background: "#e5e7eb", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, fontSize: 16, color: "#9ca3af" }}>👤</div>
                )}
                <div>
                  {speaker.position_title && (
                    <div style={{ fontSize: 11, color: "#9ca3af" }}>{speaker.position_title}</div>
                  )}
                  <div style={{ fontSize: 13, fontWeight: 600, color: "#374151" }}>{speaker.name}</div>
                </div>
              </div>
            ))}
          </div>
        ) : content.exhibitor_staff ? (
          <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 14, padding: "10px 12px", background: "#f9fafb", borderRadius: 10 }}>
            {content.exhibitor_staff.picture_url && (
              content.content_type === "booth" && !content.exhibitor_staff.position ? (
                <img src={content.exhibitor_staff.picture_url} style={{ width: 40, height: 40, borderRadius: 6, objectFit: "contain", flexShrink: 0, background: "#fff" }} />
              ) : (
                <img src={content.exhibitor_staff.picture_url} style={{ width: 40, height: 40, borderRadius: "50%", objectFit: "cover", flexShrink: 0 }} />
              )
            )}
            <div>
              {content.exhibitor_staff.position && (
                <div style={{ fontSize: 11, color: "#9ca3af" }}>{content.exhibitor_staff.position}</div>
              )}
              <div style={{ fontSize: 13, fontWeight: 600, color: "#374151" }}>{content.exhibitor_staff.name}</div>
            </div>
          </div>
        ) : null}

        {content.capacity && !content.ended && (
          <div style={{ fontSize: 12, color: "#9ca3af", marginBottom: 12 }}>
            残り {Math.max(0, content.capacity - content.usage_count)}名
          </div>
        )}

        <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
          {isParticipant && !content.ended ? (
            <a
              href={`/${eventSlug}/event_contents/${content.id}`}
              style={{
                flex: 1, display: "block", padding: "12px 16px", textAlign: "center",
                background: content.content_type === "seminar" ? "#4f46e5" : "#0ea5e9",
                color: "#fff", borderRadius: 10, fontSize: 14, fontWeight: 700,
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
                background: "#f3f4f6", color: "#374151", borderRadius: 10,
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

const EventShow = ({ props }) => {
  const { event, line_login_url, add_friend_url, current_event_path } = props;
  const [activeTab, setActiveTab] = useState("all");

  const seminars = event.contents ? event.contents.filter(c => c.content_type === "seminar") : [];
  const booths = event.contents ? event.contents.filter(c => c.content_type === "booth") : [];

  const visibleContents = activeTab === "seminar" ? seminars
    : activeTab === "booth" ? booths
    : (event.contents || []);

  return (
    <div style={{ minHeight: "100vh", background: "#f8fafc" }}>
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
              background: "rgba(6,199,85,0.15)", border: "1px solid rgba(6,199,85,0.4)",
              borderRadius: 20, padding: "6px 14px", marginBottom: 16, fontSize: 13, fontWeight: 600, color: "#4ade80"
            }}>
              <svg width="14" height="14" viewBox="0 0 20 20" fill="currentColor"><path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd"/></svg>
              参加登録済み
            </div>
          )}

          <h1 style={{ fontSize: 28, fontWeight: 800, marginBottom: 12, lineHeight: 1.3, letterSpacing: "-0.02em" }}>
            {event.title}
          </h1>

          {event.start_at && (
            <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 16, fontSize: 14, color: "rgba(255,255,255,0.75)" }}>
              <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor"><path fillRule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clipRule="evenodd"/></svg>
              {new Date(event.start_at).toLocaleDateString("ja-JP", { year: "numeric", month: "long", day: "numeric" })}
              {event.end_at && ` 〜 ${new Date(event.end_at).toLocaleDateString("ja-JP", { month: "long", day: "numeric" })}`}
            </div>
          )}

          {event.description && (
            <p style={{ fontSize: 14, lineHeight: 1.8, color: "rgba(255,255,255,0.7)", whiteSpace: "pre-wrap", marginBottom: 24 }}>
              {event.description}
            </p>
          )}

          {!event.is_participant && line_login_url && (
            <EventLineLoginLink loginUrl={line_login_url} btnText="LINEで参加登録する" />
          )}
        </div>
      </div>

      {/* Share bar */}
      <div style={{ background: "#fff", borderBottom: "1px solid #e5e7eb", padding: "12px 20px" }}>
        <div style={{ maxWidth: 720, margin: "0 auto", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <span style={{ fontSize: 12, color: "#9ca3af" }}>このイベントをシェア</span>
          <ShareButtons title={event.title} url={current_event_path} />
        </div>
      </div>

      {/* Recommendations */}
      {event.is_participant && (event.recommended_content_ids || []).length > 0 && (() => {
        const recContents = (event.recommended_content_ids || [])
          .map(id => (event.contents || []).find(c => c.id === id))
          .filter(Boolean);
        if (recContents.length === 0) return null;
        return (
          <div style={{ background: "#fefce8", borderBottom: "1px solid #fde68a", padding: "24px 16px" }}>
            <div style={{ maxWidth: 720, margin: "0 auto" }}>
              <h2 style={{ fontSize: 17, fontWeight: 800, marginBottom: 16, color: "#92400e" }}>
                🎯 あなたのお悩みにおすすめ
              </h2>
              <div style={{ display: "flex", gap: 12, overflowX: "auto", paddingBottom: 4 }}>
                {recContents.map(content => (
                  <a
                    key={content.id}
                    href={`/${event.slug}/event_contents/${content.id}`}
                    style={{
                      flex: "0 0 260px", background: "#fff", borderRadius: 14,
                      overflow: "hidden", textDecoration: "none", color: "inherit",
                      boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
                      border: "1px solid #fde68a"
                    }}
                  >
                    {content.thumbnail_url ? (
                      <img src={content.thumbnail_url} style={{ width: "100%", height: 130, objectFit: "cover", display: "block" }} />
                    ) : (
                      <div style={{
                        height: 80,
                        background: content.content_type === "seminar"
                          ? "linear-gradient(135deg, #4f46e5, #7c3aed)"
                          : "linear-gradient(135deg, #0ea5e9, #06b6d4)",
                        display: "flex", alignItems: "center", justifyContent: "center"
                      }}>
                        <span style={{ fontSize: 28 }}>{content.content_type === "seminar" ? "🎬" : "📄"}</span>
                      </div>
                    )}
                    <div style={{ padding: "10px 14px" }}>
                      <div style={{ display: "flex", gap: 4, marginBottom: 6 }}>
                        <span style={{
                          fontSize: 10, padding: "2px 8px", borderRadius: 10, fontWeight: 600, color: "#fff",
                          background: content.content_type === "seminar" ? "rgba(79,70,229,0.85)" : "rgba(14,165,233,0.85)"
                        }}>
                          {content.content_type === "seminar" ? "セミナー" : "展示ブース"}
                        </span>
                      </div>
                      <div style={{ fontWeight: 700, fontSize: 14, lineHeight: 1.4, color: "#111827",
                        display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden"
                      }}>
                        {content.title}
                      </div>
                      {content.exhibitor_staff && (
                        <div style={{ fontSize: 12, color: "#6b7280", marginTop: 4 }}>{content.exhibitor_staff.name}</div>
                      )}
                    </div>
                  </a>
                ))}
              </div>
            </div>
          </div>
        );
      })()}

      {/* Tabs */}
      {seminars.length > 0 && booths.length > 0 && (
        <div style={{ background: "#fff", borderBottom: "1px solid #e5e7eb", position: "sticky", top: 0, zIndex: 10 }}>
          <div style={{ maxWidth: 720, margin: "0 auto", display: "flex" }}>
            {[["all", `すべて (${(event.contents || []).length})`], ["seminar", `セミナー (${seminars.length})`], ["booth", `展示ブース (${booths.length})`]].map(([val, label]) => (
              <button
                key={val}
                onClick={() => setActiveTab(val)}
                style={{
                  flex: 1, padding: "14px 8px", background: "none", border: "none",
                  borderBottom: `3px solid ${activeTab === val ? "#4f46e5" : "transparent"}`,
                  color: activeTab === val ? "#4f46e5" : "#6b7280",
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
      <div style={{ maxWidth: 720, margin: "0 auto", padding: "24px 16px" }}>
        {visibleContents.length === 0 ? (
          <div style={{ textAlign: "center", padding: "60px 20px" }}>
            <div style={{ fontSize: 48, marginBottom: 12 }}>📋</div>
            <p style={{ color: "#9ca3af", fontSize: 15 }}>コンテンツはまだありません</p>
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
          borderTop: "1px solid #e5e7eb", padding: "12px 20px"
        }}>
          <div style={{ maxWidth: 720, margin: "0 auto", display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12 }}>
            <span style={{ fontSize: 13, fontWeight: 600, color: "#374151" }}>参加登録して全コンテンツにアクセス</span>
            <EventLineLoginLink loginUrl={line_login_url} btnText="参加登録" style={{ flexShrink: 0 }} />
          </div>
        </div>
      )}
    </div>
  );
};

export default EventShow;
