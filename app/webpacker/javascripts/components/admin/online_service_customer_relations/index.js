import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function AdminOnlineServiceRelationsIndex({ userId, socialServiceUserId }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!userId && !socialServiceUserId) {
      setLoading(false);
      return undefined;
    }

    let cancelled = false;
    const params = new URLSearchParams();
    if (userId) params.set("user_id", userId);
    else params.set("social_service_user_id", socialServiceUserId);
    compatRead(`/admin/online_service_customer_relations?${params}`)
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
      {items.map((item) => (
        <li key={item.id}>
          {new Date(item.created_at).toLocaleDateString()} — {item.online_service_name}{" "}
          {item.sale_page_public_path ? (
            <a href={item.sale_page_public_path} target="_blank" rel="noreferrer">
              sale page
            </a>
          ) : null}{" "}
          {item.customer_name} {item.payment_state} {item.product_amount}
        </li>
      ))}
    </ul>
  );
}

AdminOnlineServiceRelationsIndex.propTypes = {
  userId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  socialServiceUserId: PropTypes.string,
};
