import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

function formatDate(iso) {
  if (!iso) return "未設定";
  return new Date(iso).toLocaleString();
}

export default function AdminEventsIndex({ adminEventPathPrefix }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead("/admin/events")
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
    return () => { cancelled = true; };
  }, []);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;

  if (!items.length) {
    return <div className="admin-event-empty">イベントはまだありません</div>;
  }

  return (
    <>
      {items.map((event) => (
        <a key={event.id} className="admin-event-card" href={`${adminEventPathPrefix}/${event.id}`}>
          <div className="admin-event-card-title">
            {event.name}
            {event.published ? (
              <span className="admin-badge admin-badge-success">公開中</span>
            ) : (
              <span className="admin-badge admin-badge-secondary">非公開</span>
            )}
          </div>
          <div className="admin-event-card-meta">
            /{event.slug}
            {event.start_at && (
              <>
                {" "}&middot; {formatDate(event.start_at)} 〜 {formatDate(event.end_at)}
              </>
            )}
            {" "}&middot; 参加者: {event.participants_count ?? 0}人
          </div>
        </a>
      ))}
    </>
  );
}

AdminEventsIndex.propTypes = {
  adminEventPathPrefix: PropTypes.string.isRequired,
};
