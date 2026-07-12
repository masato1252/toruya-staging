import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { loadStripe } from "@stripe/stripe-js";
import { compatRead } from "../../../../libraries/compat_api";

export default function ShopsIndex({
  businessOwnerId,
  setupPendingWarning,
  addShopLabel,
  stripeKey,
}) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [adding, setAdding] = useState(false);

  const addShop = async (paymentIntentId = null) => {
    setAdding(true);
    setError(null);
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
      const response = await fetch(`/lines/user_bot/owner/${businessOwnerId}/settings/shops`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          ...(csrfToken ? { "X-CSRF-Token": csrfToken } : {}),
        },
        body: JSON.stringify(paymentIntentId ? { payment_intent_id: paymentIntentId } : {}),
      });
      const body = await response.json();
      if (body.error_type === "requires_action" && body.client_secret && stripeKey) {
        const stripe = await loadStripe(stripeKey);
        const result = body.setup_intent_id
          ? await stripe?.confirmCardSetup(body.client_secret)
          : await stripe?.confirmCardPayment(body.client_secret);
        if (result?.error) throw new Error(result.error.message);
        if (body.setup_intent_id) return addShop();
        if (result?.paymentIntent?.id) return addShop(result.paymentIntent.id);
      }
      if (!response.ok || body.status === "failed") throw new Error(body.error_message || "店舗の追加に失敗しました");
      window.location.assign(body.redirect_to);
    } catch (requestError) {
      setError(requestError.message);
      setAdding(false);
    }
  };

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
      <button type="button" className="field-row shop-add-row" onClick={() => addShop()} disabled={adding}>
        <div className="shop-add-row__label">
          <i className="fa fa-plus shop-add-row__icon" aria-hidden="true" />
          <span>{adding ? "処理中..." : addShopLabel}</span>
        </div>
      </button>
    </>
  );
}

ShopsIndex.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  setupPendingWarning: PropTypes.string.isRequired,
  addShopLabel: PropTypes.string.isRequired,
  stripeKey: PropTypes.string,
};
