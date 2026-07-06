import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../../libraries/compat_api";

export default function EquipmentsIndex({ businessOwnerId, shopId, quantityLabel, emptyLabel }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;

    compatRead(
      `/lines/user_bot/owner/${businessOwnerId}/settings/shops/${shopId}/equipments`
    )
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
  }, [businessOwnerId, shopId]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;

  if (!items.length) {
    return <div className="margin-around centerize"><div className="desc">{emptyLabel}</div></div>;
  }

  return (
    <>
      {items.map((equipment) => (
        <a
          key={equipment.id}
          className="field-row"
          href={`/lines/user_bot/owner/${businessOwnerId}/settings/shops/${shopId}/equipments/${equipment.id}`}
        >
          <div className="dotdotdot">
            <h3>{equipment.name}</h3>
            <div className="desc">
              {quantityLabel}: {equipment.quantity}
            </div>
          </div>
          <i className="fa fa-angle-right" />
        </a>
      ))}
    </>
  );
}

EquipmentsIndex.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  shopId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  quantityLabel: PropTypes.string.isRequired,
  emptyLabel: PropTypes.string.isRequired,
};
