import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function EventsIndex({ businessOwnerId, labels }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/lines/user_bot/owner/${businessOwnerId}/events`)
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

  if (loading) return <div className="booking-pages-list"><p>{labels.loading}</p></div>;
  if (error) return <div className="booking-pages-list danger"><p>{error}</p></div>;

  return (
    <div className="booking-pages-list">
      {items.map((event) => (
        <div className="field-row with-next-arrow" key={event.id}>
          <a href={`/lines/user_bot/owner/${businessOwnerId}/events/${event.id}`} className="w-full">
            <h3 className="text-gray-700 underline">{event.name}</h3>
            <div className="desc text-sm">
              {event.published ? labels.published : labels.draft}
            </div>
          </a>
        </div>
      ))}
      {!items.length && (
        <div className="field-row centerize text-gray-500">
          <p>{labels.empty}</p>
        </div>
      )}
    </div>
  );
}

EventsIndex.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  labels: PropTypes.object.isRequired,
};
