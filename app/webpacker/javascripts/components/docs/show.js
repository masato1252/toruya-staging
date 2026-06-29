"use strict";

import React from "react";

const LineLoginButton = ({ loginUrl }) => (
  <a
    href={loginUrl}
    style={{
      display: "inline-flex", alignItems: "center", gap: 8,
      padding: "14px 28px", background: "#06c755", color: "#fff",
      borderRadius: 30, fontSize: 15, fontWeight: "bold",
      textDecoration: "none", cursor: "pointer", boxShadow: "0 4px 14px rgba(6,199,85,0.4)",
      width: "100%", justifyContent: "center", maxWidth: 360
    }}
  >
    <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M19.365 9.863c.349 0 .63.285.63.631 0 .345-.281.63-.63.63H17.61v1.125h1.755c.349 0 .63.283.63.63 0 .344-.281.629-.63.629h-2.386c-.345 0-.627-.285-.627-.629V8.108c0-.345.282-.63.63-.63h2.386c.346 0 .627.285.627.63 0 .349-.281.63-.63.63H17.61v1.125h1.755zm-3.855 3.016c0 .27-.174.51-.432.596-.064.021-.133.031-.199.031-.211 0-.391-.09-.51-.25l-2.443-3.317v2.94c0 .344-.279.629-.631.629-.346 0-.626-.285-.626-.629V8.108c0-.27.173-.51.43-.595.06-.023.136-.033.194-.033.195 0 .375.104.495.254l2.462 3.33V8.108c0-.345.282-.63.63-.63.345 0 .63.285.63.63v4.771zm-5.741 0c0 .344-.282.629-.631.629-.345 0-.627-.285-.627-.629V8.108c0-.345.282-.63.63-.63.346 0 .628.285.628.63v4.771zm-2.466.629H4.917c-.345 0-.63-.285-.63-.629V8.108c0-.345.285-.63.63-.63.348 0 .63.285.63.63v4.141h1.756c.348 0 .629.283.629.63 0 .344-.282.629-.629.629M24 10.314C24 4.943 18.615.572 12 .572S0 4.943 0 10.314c0 4.811 4.27 8.842 10.035 9.608.391.082.923.258 1.058.59.12.301.079.766.038 1.08l-.164 1.02c-.045.301-.24 1.186 1.049.645 1.291-.539 6.916-4.078 9.436-6.975C23.176 14.393 24 12.458 24 10.314"/>
    </svg>
    ログインしてダウンロード
  </a>
);

const DocShow = ({ props }) => {
  const { doc, line_login_url, download_url, is_logged_in } = props;
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  const accentColor = "#60938a";

  return (
    <div style={{ minHeight: "100vh", background: "#fafaf9", padding: "24px 16px 48px" }}>
      <div style={{ maxWidth: 560, margin: "0 auto" }}>
        {doc.thumbnail_url && (
          <div style={{ overflow: "hidden", borderRadius: 8, marginBottom: 20 }}>
            <img
              src={doc.thumbnail_url}
              alt={doc.title}
              style={{ width: "100%", display: "block", objectFit: "cover" }}
            />
          </div>
        )}

        <h1 style={{ fontSize: 22, fontWeight: 800, color: "#1c1917", lineHeight: 1.4, margin: "0 0 12px", textAlign: "center" }}>
          {doc.title}
        </h1>

        {doc.description && (
          <p style={{ color: "#57534e", fontSize: 14, lineHeight: 1.8, whiteSpace: "pre-wrap", marginBottom: 24, textAlign: "center" }}>
            {doc.description}
          </p>
        )}

        <div style={{ textAlign: "center", marginTop: 28 }}>
          {is_logged_in ? (
            <form method="post" action={download_url}>
              <input type="hidden" name="authenticity_token" value={csrfToken} />
              <button
                type="submit"
                style={{
                  display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 8,
                  width: "100%", maxWidth: 360, padding: "14px 28px",
                  background: accentColor, color: "#fff", border: "none",
                  borderRadius: 8, fontSize: 16, fontWeight: 700,
                  cursor: "pointer", boxShadow: `0 4px 14px ${accentColor}66`
                }}
              >
                <svg width="18" height="18" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path fillRule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clipRule="evenodd"/>
                </svg>
                ダウンロード
              </button>
            </form>
          ) : (
            line_login_url && <LineLoginButton loginUrl={line_login_url} />
          )}
        </div>
      </div>
    </div>
  );
};

export default DocShow;
