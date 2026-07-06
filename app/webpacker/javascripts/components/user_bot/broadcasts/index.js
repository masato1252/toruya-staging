import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

function formatDeliverAt(iso) {
  if (!iso) return "";
  return new Date(iso).toLocaleString();
}

export default function BroadcastsIndex({
  businessOwnerId,
  newBroadcastPath,
  queryTypeLabels,
  noBroadcastsTitle,
  noBroadcastsDesc,
  permissionWarning,
}) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/lines/user_bot/owner/${businessOwnerId}/broadcasts`)
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
  }, [businessOwnerId]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;

  if (!items.length) {
    return (
      <>
        <div className="dotdotdot margin-around centerize">
          <h3>{noBroadcastsTitle}</h3>
          <div className="desc margin-around">{noBroadcastsDesc}</div>
        </div>
        {newBroadcastPath && (
          <div className="margin-around centerize hidden-xs">
            <a className="btn btn-yellow" href={newBroadcastPath}><i className="fa fa-plus" /> Add more</a>
          </div>
        )}
      </>
    );
  }

  return (
    <>
      {items.map((broadcast) => (
        <a
          key={broadcast.id}
          className="field-row with-next-arrow"
          href={`/lines/user_bot/owner/${businessOwnerId}/broadcasts/${broadcast.id}`}
        >
          <div className="dotdotdot">
            <h3 className="underline">{formatDeliverAt(broadcast.deliver_at)}</h3>
            <div className="desc">{queryTypeLabels[broadcast.query_type] || broadcast.query_type}</div>
            <div className="desc">{broadcast.targets?.join(", ")}</div>
            {broadcast.customers_permission_warning && (
              <div className="desc warning">{permissionWarning}</div>
            )}
          </div>
        </a>
      ))}
      {newBroadcastPath && (
        <div className="margin-around centerize hidden-xs">
          <a className="btn btn-yellow" href={newBroadcastPath}><i className="fa fa-plus" /> Add more</a>
        </div>
      )}
    </>
  );
}

BroadcastsIndex.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  newBroadcastPath: PropTypes.string,
  queryTypeLabels: PropTypes.object.isRequired,
  noBroadcastsTitle: PropTypes.string.isRequired,
  noBroadcastsDesc: PropTypes.string.isRequired,
  permissionWarning: PropTypes.string.isRequired,
};
