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
