import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function ServiceShow({ businessOwnerId, serviceId, labels }) {
  const [service, setService] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/lines/user_bot/owner/${businessOwnerId}/services/${serviceId}/page_context`)
      .then((body) => {
        if (cancelled) return;
        setService(body.data || null);
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
  }, [businessOwnerId, serviceId]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;
  if (!service) return null;

  const base = `/lines/user_bot/owner/${businessOwnerId}/services/${serviceId}`;

  return (
    <>
      <div className="field-group-header">{labels.about}</div>
      <a className="field-row" href={`${base}/edit?attribute=name`}>
        <span>{labels.name}: {service.display_name || service.name}</span>
      </a>
      {service.internal_name && (
        <a className="field-row" href={`${base}/edit?attribute=internal_name`}>
          <span>{labels.internalName}: {service.internal_name}</span>
        </a>
      )}
      {service.missing_sale_page && (
        <div className="field-row warning">
          <i className="fas fa-exclamation-circle" /> {labels.noSalePage}
        </div>
      )}
      {service.missing_chapters && (
        <div className="field-row warning">{labels.noChapters}</div>
      )}
      {service.public_url_path && (
        <a className="field-row" href={service.public_url_path} target="_blank" rel="noreferrer">
          <span>{labels.publicUrl}</span>
        </a>
      )}
    </>
  );
}

ServiceShow.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  serviceId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  labels: PropTypes.object.isRequired,
};
