import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../libraries/compat_api";

export default function PublicBookingBootstrap({ slug, bookingBasePath }) {
  const [ctx, setCtx] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/booking/${slug}/page_context`)
      .then((body) => {
        if (cancelled) return;
        const page = body.data || {};
        const includes = body.includes || {};
        setCtx({
          page,
          shop: includes.shop,
          options: includes.booking_options || [],
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
  if (!ctx?.page) return null;

  const { page, shop, options } = ctx;
  const base = bookingBasePath || `/booking/${slug}`;

  return (
    <div className="booking-page-bootstrap container margin-around">
      {shop?.name && <h2>{shop.name}</h2>}
      <h1>{page.title || page.name}</h1>
      {page.greeting && <p className="greeting">{page.greeting}</p>}
      {page.note && <p className="note">{page.note}</p>}

      <div className="booking-options-list">
        {options.length === 0 && (
          <p className="warning">No booking options available.</p>
        )}
        {options.map((opt) => (
          <a
            key={opt.id}
            className="btn btn-tarco btn-block margin-around"
            href={`${base}?booking_option_ids=${opt.id}`}
          >
            {opt.display_name || opt.name}
            {opt.minutes ? ` (${opt.minutes} min)` : ""}
          </a>
        ))}
      </div>
    </div>
  );
}

PublicBookingBootstrap.propTypes = {
  slug: PropTypes.string.isRequired,
  bookingBasePath: PropTypes.string,
};
