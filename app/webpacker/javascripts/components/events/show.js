"use strict"

import React, { useState } from "react";

const ShareButtons = ({ title, url }) => {
  const encodedUrl = encodeURIComponent(url);
  const encodedTitle = encodeURIComponent(title);

  const handleDownloadThumbnail = (thumbnailUrl) => {
    const a = document.createElement("a");
    a.href = thumbnailUrl;
    a.download = "thumbnail.jpg";
    a.click();
  };

  return (
    <div style={{ display: "flex", gap: 12, flexWrap: "wrap", marginTop: 16 }}>
      <a
        href={`https://www.instagram.com/`}
        target="_blank"
        rel="noopener noreferrer"
        style={{ padding: "8px 16px", background: "linear-gradient(45deg, #f09433, #e6683c, #dc2743, #cc2366, #bc1888)", color: "#fff", borderRadius: 20, fontSize: 13, textDecoration: "none" }}
      >
        <i className="fab fa-instagram"></i> Instagram
      </a>
      <a
        href={`https://www.facebook.com/sharer/sharer.php?u=${encodedUrl}`}
        target="_blank"
        rel="noopener noreferrer"
        style={{ padding: "8px 16px", background: "#1877f2", color: "#fff", borderRadius: 20, fontSize: 13, textDecoration: "none" }}
      >
        <i className="fab fa-facebook"></i> Facebook
      </a>
      <a
        href={`https://twitter.com/intent/tweet?text=${encodedTitle}&url=${encodedUrl}`}
        target="_blank"
        rel="noopener noreferrer"
        style={{ padding: "8px 16px", background: "#000", color: "#fff", borderRadius: 20, fontSize: 13, textDecoration: "none" }}
      >
        <i className="fab fa-x-twitter"></i> X
      </a>
    </div>
  );
};

const ContentCard = ({ content, eventSlug, isParticipant, lineLoginUrl }) => {
  const [isStarting, setIsStarting] = useState(false);

  const handleStartUsage = async () => {
    if (!isParticipant) {
      window.location = lineLoginUrl || `/events/${eventSlug}/participation/new`;
      return;
    }
    setIsStarting(true);
    window.location = `/events/${eventSlug}/event_contents/${content.id}`;
  };

  const statusBadge = () => {
    if (content.ended) return <span style={{ background: "#999", color: "#fff", fontSize: 11, padding: "2px 8px", borderRadius: 10 }}>終了</span>;
    if (!content.started) return <span style={{ background: "#f0a000", color: "#fff", fontSize: 11, padding: "2px 8px", borderRadius: 10 }}>開始前</span>;
    if (content.capacity_full) return <span style={{ background: "#e53e3e", color: "#fff", fontSize: 11, padding: "2px 8px", borderRadius: 10 }}>満員</span>;
    return <span style={{ background: "#00b900", color: "#fff", fontSize: 11, padding: "2px 8px", borderRadius: 10 }}>受付中</span>;
  };

  const ctaLabel = () => {
    if (content.content_type === "seminar") return "セミナーを視聴する";
    return "出展ブースに入る";
  };

  return (
    <div style={{
      border: "1px solid #e2e8f0",
      borderRadius: 12,
      overflow: "hidden",
      marginBottom: 20,
      background: "#fff",
      boxShadow: "0 2px 8px rgba(0,0,0,0.06)"
    }}>
      {content.thumbnail_url && (
        <div style={{ position: "relative" }}>
          <img src={content.thumbnail_url} style={{ width: "100%", height: 180, objectFit: "cover" }} />
          <div style={{ position: "absolute", top: 8, left: 8 }}>
            {statusBadge()}
          </div>
          <div style={{ position: "absolute", top: 8, right: 8, background: "rgba(0,0,0,0.6)", color: "#fff", fontSize: 11, padding: "2px 8px", borderRadius: 10 }}>
            {content.content_type === "seminar" ? "🎬 セミナー動画" : "📄 展示ブース"}
          </div>
        </div>
      )}
      <div style={{ padding: "16px" }}>
        <h3 style={{ fontWeight: "bold", fontSize: 16, marginBottom: 8 }}>{content.title}</h3>
        {content.introduction && (
          <p style={{ color: "#666", fontSize: 13, marginBottom: 12, lineHeight: 1.6 }}>{content.introduction}</p>
        )}

        <div style={{ display: "flex", gap: 8, alignItems: "center", marginBottom: 12, flexWrap: "wrap" }}>
          {content.capacity && (
            <span style={{ fontSize: 12, color: "#888" }}>
              残り {Math.max(0, content.capacity - content.usage_count)}名
            </span>
          )}
        </div>

        <button
          onClick={handleStartUsage}
          disabled={content.ended || isStarting}
          style={{
            width: "100%",
            padding: "12px",
            background: content.ended ? "#ccc" : "#00b900",
            color: "#fff",
            border: "none",
            borderRadius: 8,
            fontSize: 15,
            fontWeight: "bold",
            cursor: content.ended ? "not-allowed" : "pointer"
          }}
        >
          {content.ended ? "このコンテンツは終了しました" : ctaLabel()}
        </button>

        <div style={{ marginTop: 12 }}>
          <ShareButtons
            title={content.title}
            url={`${window.location.origin}/events/${eventSlug}/event_contents/${content.id}`}
          />
        </div>
      </div>
    </div>
  );
};

const EventShow = ({ props }) => {
  const { event, line_login_url, current_event_path } = props;
  const [activeTab, setActiveTab] = useState("all");

  const seminars = event.contents ? event.contents.filter(c => c.content_type === "seminar") : [];
  const booths = event.contents ? event.contents.filter(c => c.content_type === "booth") : [];

  const visibleContents = activeTab === "seminar" ? seminars
    : activeTab === "booth" ? booths
    : (event.contents || []);

  return (
    <div style={{ minHeight: "100vh", background: "#f7f8fc" }}>
      {/* Hero Section */}
      <div style={{ background: "linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%)", color: "#fff", padding: "40px 20px" }}>
        <div style={{ maxWidth: 800, margin: "0 auto", textAlign: "center" }}>
          <h1 style={{ fontSize: 28, fontWeight: "bold", marginBottom: 12 }}>{event.title}</h1>
          {event.description && (
            <p style={{ fontSize: 15, opacity: 0.85, lineHeight: 1.7, whiteSpace: "pre-wrap" }}>{event.description}</p>
          )}
          {event.start_at && (
            <div style={{ marginTop: 16, fontSize: 14, opacity: 0.8 }}>
              📅 {new Date(event.start_at).toLocaleDateString("ja-JP")} 〜 {event.end_at ? new Date(event.end_at).toLocaleDateString("ja-JP") : ""}
            </div>
          )}

          {!event.is_participant && (
            <div style={{ marginTop: 24 }}>
              <a
                href={line_login_url || `/events/${event.slug}/participation/new`}
                style={{
                  display: "inline-block",
                  padding: "14px 32px",
                  background: "#00b900",
                  color: "#fff",
                  borderRadius: 30,
                  fontSize: 16,
                  fontWeight: "bold",
                  textDecoration: "none"
                }}
              >
                🎟️ イベントに参加登録する
              </a>
            </div>
          )}
        </div>
      </div>

      {/* Share Buttons */}
      <div style={{ background: "#fff", padding: "16px 20px", borderBottom: "1px solid #eee" }}>
        <div style={{ maxWidth: 800, margin: "0 auto" }}>
          <p style={{ fontSize: 13, color: "#888", marginBottom: 8 }}>このイベントをシェアする</p>
          <ShareButtons title={event.title} url={current_event_path} />
        </div>
      </div>

      {/* Tabs */}
      {seminars.length > 0 && booths.length > 0 && (
        <div style={{ background: "#fff", borderBottom: "1px solid #eee" }}>
          <div style={{ maxWidth: 800, margin: "0 auto", display: "flex" }}>
            {[["all", "すべて"], ["seminar", `セミナー (${seminars.length})`], ["booth", `展示ブース (${booths.length})`]].map(([val, label]) => (
              <button
                key={val}
                onClick={() => setActiveTab(val)}
                style={{
                  flex: 1,
                  padding: "14px 8px",
                  background: "none",
                  border: "none",
                  borderBottom: `3px solid ${activeTab === val ? "#00b900" : "transparent"}`,
                  color: activeTab === val ? "#00b900" : "#666",
                  fontWeight: activeTab === val ? "bold" : "normal",
                  cursor: "pointer",
                  fontSize: 14
                }}
              >
                {label}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Content List */}
      <div style={{ maxWidth: 800, margin: "0 auto", padding: "24px 16px" }}>
        {visibleContents.length === 0 && (
          <p style={{ textAlign: "center", color: "#999", padding: 40 }}>コンテンツはまだありません</p>
        )}
        {visibleContents.map(content => (
          <ContentCard
            key={content.id}
            content={content}
            eventSlug={event.slug}
            isParticipant={event.is_participant}
            lineLoginUrl={line_login_url}
          />
        ))}
      </div>
    </div>
  );
};

export default EventShow;
