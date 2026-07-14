import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function AdminSalePagesIndex({ userId, socialServiceUserId, salePagePathPrefix }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!userId && !socialServiceUserId) {
      setLoading(false);
      return;
    }
    let cancelled = false;
    const params = new URLSearchParams();
    if (userId) params.set("user_id", userId);
    else params.set("social_service_user_id", socialServiceUserId);
    compatRead(`/admin/sale_pages?${params}`)
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
  }, [userId, socialServiceUserId]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;

  return (
    <ul>
      {items.map((sale) => (
        <li key={sale.id}>
          {new Date(sale.updated_at).toLocaleString()} —{" "}
          {sale.is_booking_page ? <i className="fa fa-calendar" /> : <i className="fa fa-mobile-alt" />}{" "}
          {sale.public_url_path ? (
            <a href={sale.public_url_path} target="_blank" rel="noreferrer">
              {sale.name}
            </a>
          ) : (
            sale.name
          )}
          {sale.product_name && <span className="desc"> ({sale.product_name})</span>}
        </li>
      ))}
    </ul>
  );
}

AdminSalePagesIndex.propTypes = {
  userId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  socialServiceUserId: PropTypes.string,
  salePagePathPrefix: PropTypes.string,
};
