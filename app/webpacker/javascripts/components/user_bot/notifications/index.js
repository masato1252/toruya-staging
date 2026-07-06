import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function NotificationsIndex({ businessOwnerId, schedulesPath, labels }) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/lines/user_bot/owner/${businessOwnerId}/notifications`)
      .then((body) => {
        if (cancelled) return;
        const payload = body.data || {};
        setData(payload);
        if (!payload.has_notifications && schedulesPath) {
          window.location.href = schedulesPath;
        }
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
  }, [businessOwnerId, schedulesPath]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;
  if (!data?.has_notifications) return null;

  return (
    <div className="booking-pages-list">
      {data.pending_reservations_count > 0 && (
        <a className="field-row with-next-arrow" href={schedulesPath}>
          <span>{labels.pendingReservations}: {data.pending_reservations_count}</span>
        </a>
      )}
      {data.unread_messages_count > 0 && (
        <div className="field-row">
          <span>{labels.unreadMessages}: {data.unread_messages_count}</span>
        </div>
      )}
    </div>
  );
}

NotificationsIndex.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  schedulesPath: PropTypes.string,
  labels: PropTypes.object.isRequired,
};
