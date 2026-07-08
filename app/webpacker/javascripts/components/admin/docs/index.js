import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function AdminDocsIndex({ newDocHref }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead("/admin/docs")
      .then((body) => {
        if (cancelled) return;
        setItems(body.data || []);
      })
      .catch((err) => {
        if (!cancelled) setError(err.message);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;

  return (
    <div className="admin-event-list">
      <div className="admin-event-list-header">
        <h2>資料DL一覧</h2>
        <a href={newDocHref} className="btn btn-tarco">
          新規追加
        </a>
      </div>

      {items.length ? (
        items.map((doc) => (
          <div key={doc.id} className="admin-event-card" style={{ display: "block", textDecoration: "none", color: "inherit" }}>
            <div className="admin-event-card-title">
              <a href={doc.show_href} style={{ color: "inherit", textDecoration: "none" }}>
                {doc.title}
              </a>{" "}
              {doc.status === "published" ? (
                <span className="admin-badge admin-badge-success">公開中</span>
              ) : (
                <span className="admin-badge admin-badge-secondary">非公開</span>
              )}
            </div>
            <div className="admin-event-card-meta">
              動線URL: <code>{doc.public_path}</code>
            </div>
            <div className="admin-event-card-meta" style={{ marginTop: 6 }}>
              <a href={doc.show_href} className="btn btn-gray btn-sm">
                詳細
              </a>{" "}
              <a href={doc.edit_href} className="btn btn-tarco btn-sm">
                編集
              </a>
            </div>
          </div>
        ))
      ) : (
        <div className="admin-event-empty">資料はまだありません</div>
      )}
    </div>
  );
}

AdminDocsIndex.propTypes = {
  newDocHref: PropTypes.string.isRequired,
};
