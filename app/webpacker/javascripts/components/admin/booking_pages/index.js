import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function AdminBookingPagesIndex({ userId, socialServiceUserId, bookingPagePathPrefix }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    const params = new URLSearchParams();
    if (userId) params.set("user_id", userId);
    else if (socialServiceUserId) params.set("social_service_user_id", socialServiceUserId);
    const suffix = params.toString() ? `?${params}` : "";
    compatRead(`/admin/booking_pages${suffix}`)
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
  }, [userId, socialServiceUserId]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;

  return (
    <ul>
      {items.map((page) => (
        <li key={page.id}>
          {new Date(page.updated_at).toLocaleString()} —{" "}
          <a href={`${bookingPagePathPrefix}/${page.slug}`} target="_blank" rel="noreferrer">
            {page.name}
          </a>
        </li>
      ))}
    </ul>
  );
}

AdminBookingPagesIndex.propTypes = {
  userId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  socialServiceUserId: PropTypes.string,
  bookingPagePathPrefix: PropTypes.string.isRequired,
};
