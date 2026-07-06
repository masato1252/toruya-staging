import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function SalesIndex({ businessOwnerId, newSalePath }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/lines/user_bot/owner/${businessOwnerId}/sales`)
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
  }, [businessOwnerId]);

  if (loading) return <div className="booking-pages-list"><p>Loading...</p></div>;
  if (error) return <div className="booking-pages-list danger"><p>{error}</p></div>;

  return (
    <div className="booking-pages-list">
      {items.map((sale) => (
        <div className="field-row with-next-arrow" key={sale.id}>
          <a className="w-8-12" href={`/lines/user_bot/owner/${businessOwnerId}/sales/${sale.id}`}>
            <h3 className="text-gray-700 underline">
              <i className={`fa ${sale.is_booking_page ? "fa-calendar" : "fa-mobile-alt"}`} />
              {sale.draft ? "[Draft]" : ""}{sale.name}
            </h3>
            <div className="desc">{sale.product_name}</div>
          </a>
        </div>
      ))}
      {newSalePath && (
        <div className="margin-around centerize hidden-xs">
          <a className="btn btn-yellow" href={newSalePath}><i className="fa fa-plus" /> Add more</a>
        </div>
      )}
    </div>
  );
}

SalesIndex.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  newSalePath: PropTypes.string,
};
