import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function MetricsOnlineServicesIndex({ businessOwnerId, metricsServicePathPrefix }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/lines/user_bot/owner/${businessOwnerId}/services`)
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

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;

  return (
    <div className="booking-pages-list">
      {items.map((service) => (
        <a
          key={service.id}
          className="field-row with-next-arrow"
          href={`${metricsServicePathPrefix}/${service.id}`}
        >
          <div>
            <h3>{service.display_name || service.name}</h3>
          </div>
          <i className="fa fa-angle-right" />
        </a>
      ))}
    </div>
  );
}

MetricsOnlineServicesIndex.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  metricsServicePathPrefix: PropTypes.string.isRequired,
};
