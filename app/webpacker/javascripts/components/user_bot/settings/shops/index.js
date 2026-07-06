import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../../libraries/compat_api";

export default function ShopsIndex({
  businessOwnerId,
  setupPendingWarning,
}) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;

    compatRead(`/lines/user_bot/owner/${businessOwnerId}/settings/shops`)
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
  }, [businessOwnerId]);

  if (loading) {
    return <p>Loading...</p>;
  }

  if (error) {
    return <p className="danger">{error}</p>;
  }

  return (
    <>
      {items.map((shop) => (
        <a
          key={shop.id}
          className="field-row"
          href={`/lines/user_bot/owner/${businessOwnerId}/settings/shops/${shop.id}`}
        >
          <div>
            <span>{shop.name}</span>
            {shop.setup_pending && (
              <div className="shop-setup-pending-warning">
                <i className="fa-solid fa-circle-exclamation" />
                {setupPendingWarning}
              </div>
            )}
          </div>
          <i className="fa fa-angle-right" />
        </a>
      ))}
    </>
  );
}

ShopsIndex.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  setupPendingWarning: PropTypes.string.isRequired,
};
