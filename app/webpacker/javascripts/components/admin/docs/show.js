import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function AdminDocShow({ docId, docsHref }) {
  const [doc, setDoc] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/admin/docs/${docId}/page_context`)
      .then((body) => {
        if (!cancelled) setDoc(body.data);
      })
      .catch((requestError) => {
        if (!cancelled) setError(requestError.message);
      });
    return () => {
      cancelled = true;
    };
  }, [docId]);

  if (error) return <p className="danger">{error}</p>;
  if (!doc) return <p>Loading...</p>;

  return (
    <div className="admin-event-detail">
      <div className="admin-detail-header">
        <h2>{doc.title}</h2>
        <div className="admin-detail-actions">
          <a href={doc.edit_href} className="btn btn-tarco">編集</a>
          <a
            href={doc.delete_href}
            data-method="delete"
            data-confirm="この資料を削除しますか？"
            className="btn btn-danger"
          >
            削除
          </a>
        </div>
      </div>

      <div className="admin-detail-section">
        <div className="admin-form-section-title">基本情報</div>
        <div className="admin-detail-row">
          <div className="admin-detail-label">ステータス</div>
          <div className="admin-detail-value">
            <span className={`admin-badge ${doc.status === "published" ? "admin-badge-success" : "admin-badge-secondary"}`}>
              {doc.status === "published" ? "公開中" : "非公開"}
            </span>
          </div>
        </div>
        <div className="admin-detail-row">
          <div className="admin-detail-label">動線URL</div>
          <div className="admin-detail-value"><code>{doc.public_path}</code></div>
        </div>
        <div className="admin-detail-row">
          <div className="admin-detail-label">資料URL</div>
          <div className="admin-detail-value"><a href={doc.document_url} target="_blank" rel="noopener noreferrer">{doc.document_url}</a></div>
        </div>
        {doc.description ? (
          <div className="admin-detail-row">
            <div className="admin-detail-label">説明文</div>
            <div className="admin-detail-value" style={{ whiteSpace: "pre-wrap" }}>{doc.description}</div>
          </div>
        ) : null}
        {doc.thumbnail_url ? (
          <div className="admin-detail-row">
            <div className="admin-detail-label">サムネイル</div>
            <div className="admin-detail-value">
              <img src={doc.thumbnail_url} alt="" style={{ maxWidth: 320, borderRadius: 8 }} />
            </div>
          </div>
        ) : null}
      </div>

      <div className="admin-detail-section">
        <div className="admin-form-section-title">リード一覧（{doc.downloads?.length || 0}件）</div>
        {doc.downloads?.length ? (
          <div className="admin-participant-table-wrap">
            <table className="admin-participant-table">
              <thead>
                <tr>
                  <th>LINE表示名</th>
                  <th>メール</th>
                  <th>初回訪問</th>
                  <th>初回DL</th>
                  <th>DL回数</th>
                  <th>リファラ</th>
                </tr>
              </thead>
              <tbody>
                {doc.downloads.map((download) => (
                  <tr key={download.id}>
                    <td>{download.display_name}</td>
                    <td>{download.email || "—"}</td>
                    <td>{download.first_visited_at ? new Date(download.first_visited_at).toLocaleString("ja-JP") : "—"}</td>
                    <td>{download.first_downloaded_at ? new Date(download.first_downloaded_at).toLocaleString("ja-JP") : "—"}</td>
                    <td>{download.download_count}</td>
                    <td style={{ maxWidth: 240, wordBreak: "break-all" }}>{download.referrer || "—"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="admin-event-empty">リードはまだありません</div>
        )}
      </div>

      <div style={{ marginTop: 16 }}>
        <a href={docsHref} className="btn btn-gray">一覧に戻る</a>
      </div>
    </div>
  );
}

AdminDocShow.propTypes = {
  docId: PropTypes.number.isRequired,
  docsHref: PropTypes.string.isRequired,
};
