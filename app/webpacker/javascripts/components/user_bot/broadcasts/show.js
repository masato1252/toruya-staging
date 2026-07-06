import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function BroadcastShow({ businessOwnerId, broadcastId, labels }) {
  const [broadcast, setBroadcast] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/lines/user_bot/owner/${businessOwnerId}/broadcasts/${broadcastId}/page_context`)
      .then((body) => {
        if (cancelled) return;
        setBroadcast(body.data || null);
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
  }, [businessOwnerId, broadcastId]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;
  if (!broadcast) return null;

  const base = `/lines/user_bot/owner/${businessOwnerId}/broadcasts/${broadcastId}`;
  const deliverAt = broadcast.deliver_at || broadcast.schedule_at || broadcast.sent_at;

  return (
    <>
      <div className="field-header">{labels.content}</div>
      <div className="field-row">
        <p className="p10 bg-gray rounded break-line-content w-full">{broadcast.content}</p>
      </div>

      <div className="field-header">{labels.audiences}</div>
      <div className="field-row">
        <div className="w-full">{labels.queryType}: {broadcast.query_type}</div>
        {(broadcast.targets || []).map((name) => (
          <div key={name} className="btn btn-gray mx-2 my-2">{name}</div>
        ))}
      </div>

      <div className="field-header">{labels.state}</div>
      <div className="field-row">
        <span>{broadcast.state}</span>
      </div>

      {deliverAt && (
        <>
          <div className="field-header">{labels.time}</div>
          <div className="field-row">
            <span>{new Date(deliverAt).toLocaleString()}</span>
          </div>
        </>
      )}

      {broadcast.customers_permission_warning && (
        <div className="field-row warning">{labels.permissionWarning}</div>
      )}

      {broadcast.state === "draft" && (
        <div className="action-block">
          <a className="btn btn-tarco" href={`${base}/edit?attribute=content`}>
            {labels.edit}
          </a>
        </div>
      )}
    </>
  );
}

BroadcastShow.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  broadcastId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  labels: PropTypes.object.isRequired,
};
