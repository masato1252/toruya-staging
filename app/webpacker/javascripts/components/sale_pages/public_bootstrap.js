import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../libraries/compat_api";

export default function PublicSaleBootstrap({ slug }) {
  const [ctx, setCtx] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/sale_pages/${slug}/page_context`)
      .then((body) => {
        if (cancelled) return;
        const sale = body.data || {};
        const subscriptionActive = body.includes?.subscription_active;
        setCtx({ sale, subscriptionActive });
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
  if (!ctx?.sale) return null;

  const { sale, subscriptionActive } = ctx;
  const content = sale.content || {};

  if (subscriptionActive === false) {
    return <p className="warning margin-around">This service is currently unavailable.</p>;
  }

  return (
    <div className="sale-page-bootstrap container margin-around">
      <h1>{sale.name}</h1>
      {content.desc1 && <p>{content.desc1}</p>}
      {content.desc2 && <p>{content.desc2}</p>}
      {sale.selling_price_cents != null && (
        <p className="price">¥{Number(sale.selling_price_cents).toLocaleString()}</p>
      )}
    </div>
  );
}

PublicSaleBootstrap.propTypes = {
  slug: PropTypes.string.isRequired,
};
