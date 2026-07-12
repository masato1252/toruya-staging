import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function NewCompatBooking({ businessOwnerId, pageContextPath, labels }) {
  const [shops, setShops] = useState(null);
  const [error, setError] = useState(null);
  const [creatingShopId, setCreatingShopId] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(pageContextPath)
      .then((body) => {
        if (!cancelled) setShops(body.data?.edit_form?.shops || []);
      })
      .catch((requestError) => {
        if (!cancelled) setError(requestError.message);
      });
    return () => {
      cancelled = true;
    };
  }, [pageContextPath]);

  const create = async (shopId) => {
    setCreatingShopId(shopId);
    setError(null);
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
      const response = await fetch(`/lines/user_bot/owner/${businessOwnerId}/bookings/page`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          ...(csrfToken ? { "X-CSRF-Token": csrfToken } : {}),
        },
        body: JSON.stringify({ shop_id: shopId }),
      });
      const body = await response.json();
      if (!response.ok || body.status !== "successful") {
        throw new Error(body.error_message || labels.failed);
      }
      window.location.assign(body.redirect_to);
    } catch (requestError) {
      setError(requestError.message);
      setCreatingShopId(null);
    }
  };

  if (error) return <p className="danger">{error}</p>;
  if (!shops) return <p>{labels.loading}</p>;

  return (
    <div className="booking-creation-flow centerize">
      <h3 className="header">{labels.chooseShop}</h3>
      {shops.map((shop) => (
        <div key={shop.id}>
          <button
            type="button"
            className="btn btn-tarco btn-extend btn-tall"
            disabled={creatingShopId !== null}
            onClick={() => create(shop.id)}
          >
            {creatingShopId === shop.id ? labels.loading : shop.name}
          </button>
        </div>
      ))}
    </div>
  );
}

NewCompatBooking.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  pageContextPath: PropTypes.string.isRequired,
  labels: PropTypes.shape({
    chooseShop: PropTypes.string.isRequired,
    loading: PropTypes.string.isRequired,
    failed: PropTypes.string.isRequired,
  }).isRequired,
};
