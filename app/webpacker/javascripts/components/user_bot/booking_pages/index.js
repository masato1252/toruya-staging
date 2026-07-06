import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function BookingPagesIndex({ businessOwnerId, bookingsPagePath, lineKeywordPath }) {
  const [items, setItems] = useState([]);
  const [withoutOptionIds, setWithoutOptionIds] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;

    compatRead(`/lines/user_bot/owner/${businessOwnerId}/booking_pages`)
      .then((body) => {
        if (cancelled) return;
        setItems(body.data || []);
        setWithoutOptionIds(body.includes?.booking_pages_without_option_ids || []);
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

  if (loading) {
    return <div className="booking-pages-list"><p>Loading...</p></div>;
  }

  if (error) {
    return <div className="booking-pages-list danger"><p>{error}</p></div>;
  }

  return (
    <div className="booking-pages-list">
      {items.map((bookingPage) => (
        <div className="field-row with-next-arrow" key={bookingPage.id}>
          <a className="w-8-12" href={`/lines/user_bot/owner/${businessOwnerId}/booking_pages/${bookingPage.id}`}>
            <h3 className="text-gray-700 underline">{bookingPage.name}</h3>
            {bookingPage.draft && (
              <div className="desc danger"><i className="fas fa-exclamation-triangle" />&nbsp;Draft</div>
            )}
            {withoutOptionIds.includes(bookingPage.id) ? (
              <div className="desc danger"><i className="fas fa-exclamation-circle" />&nbsp;No option</div>
            ) : (
              !bookingPage.draft && (
                <>
                  <div className="desc">{bookingPage.title}</div>
                  <div className="desc">{bookingPage.booking_option_names?.join(", ")}</div>
                  <div className="desc">LINE: {bookingPage.line_sharing ? "ON" : "OFF"}</div>
                </>
              )
            )}
          </a>
        </div>
      ))}

      <div className="margin-around centerize">
        <a className="btn btn-yellow" href={bookingsPagePath}>
          <i className="fa fa-plus" /> Add more
        </a>
      </div>

      {lineKeywordPath && (
        <div className="margin-around centerize">
          <a className="btn btn-tarco" href={lineKeywordPath}>LINE settings</a>
        </div>
      )}
    </div>
  );
}

BookingPagesIndex.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  bookingsPagePath: PropTypes.string.isRequired,
  lineKeywordPath: PropTypes.string,
};
