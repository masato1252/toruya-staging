import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../libraries/compat_api";
import SaleBookingPage from "user_bot/sales/booking_pages";
import SaleOnlineService from "user_bot/sales/online_services";

export default function PublicSaleShell({ slug, supportFeatureFlags }) {
  const [payload, setPayload] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/sale_pages/${slug}/page_context`)
      .then((body) => {
        if (cancelled) return;
        const subscriptionActive = body.includes?.subscription_active;
        if (subscriptionActive === false) {
          setPayload({ unavailable: true });
          return;
        }
        setPayload({
          data: body.data || {},
          reactComponent: body.includes?.react_component,
        });
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
  }, [slug]);

  if (loading) return <p className="margin-around centerize">Loading...</p>;
  if (error) return <p className="danger margin-around">{error}</p>;
  if (!payload) return null;

  if (payload.unavailable) {
    return <p className="warning margin-around">This service is currently unavailable.</p>;
  }

  const props = {
    ...payload.data,
    demo: false,
    support_feature_flags: supportFeatureFlags,
  };

  if (payload.reactComponent === "online_services" || payload.data.is_booking_page === false) {
    return <SaleOnlineService {...props} />;
  }

  return <SaleBookingPage {...props} />;
}

PublicSaleShell.propTypes = {
  slug: PropTypes.string.isRequired,
  supportFeatureFlags: PropTypes.object,
};
