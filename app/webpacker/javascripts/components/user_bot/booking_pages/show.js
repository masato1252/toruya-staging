import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function BookingPageShow({ businessOwnerId, bookingPageId, labels }) {
  const [page, setPage] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(
      `/lines/user_bot/owner/${businessOwnerId}/booking_pages/${bookingPageId}/page_context`
    )
      .then((body) => {
        if (cancelled) return;
        setPage(body.data || null);
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
  }, [businessOwnerId, bookingPageId]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;
  if (!page) return null;

  const base = `/lines/user_bot/owner/${businessOwnerId}/booking_pages/${bookingPageId}`;

  return (
    <>
      <div className="field-group-header">{labels.basicInfo}</div>
      <a className="field-row" href={`${base}/edit?attribute=draft`}>
        <span>{labels.privacy}: {page.draft ? labels.private : labels.public}</span>
      </a>
      <a className="field-row" href={`${base}/edit?attribute=name`}>
        <span>{labels.pageName}: {page.name}</span>
      </a>
      {page.title && (
        <a className="field-row" href={`${base}/edit?attribute=title`}>
          <span>{labels.title}: {page.title}</span>
        </a>
      )}
      {page.shop_name && <div className="field-row"><span>{labels.shop}: {page.shop_name}</span></div>}
      {page.booking_option_names?.length > 0 && (
        <div className="field-header">{labels.options}</div>
      )}
      {page.booking_option_names?.map((name) => (
        <div key={name} className="field-row"><span>{name}</span></div>
      ))}
    </>
  );
}

BookingPageShow.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  bookingPageId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  labels: PropTypes.object.isRequired,
};
