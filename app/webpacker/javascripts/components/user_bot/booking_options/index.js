import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

function formatPrice(option) {
  if (option.price_text) return option.price_text;
  if (option.amount_cents == null) return "";
  const amount = Number(option.amount_cents);
  if (option.amount_currency === "JPY") {
    return `¥${amount.toLocaleString("ja-JP")}`;
  }
  return `${option.amount_currency} ${amount}`;
}

export default function BookingOptionsIndex({
  businessOwnerId,
  newBookingOptionPath,
  lineKeywordPath,
  requiredTimeLabel,
  minuteLabel,
}) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;

    compatRead(`/lines/user_bot/owner/${businessOwnerId}/booking_options`)
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

  if (loading) {
    return <div className="booking-pages-list"><p>Loading...</p></div>;
  }

  if (error) {
    return <div className="booking-pages-list danger"><p>{error}</p></div>;
  }

  return (
    <div className="booking-pages-list">
      {items.map((bookingOption) => (
        <a
          key={bookingOption.id}
          className="field-row with-next-arrow"
          href={`/lines/user_bot/owner/${businessOwnerId}/booking_options/${bookingOption.id}`}
        >
          <div>
            <h3 className="break-line-content underline">{bookingOption.name}</h3>
            {bookingOption.menu_names?.length > 0 && (
              <div className="desc">{bookingOption.menu_names.join(", ")}</div>
            )}
            <div className="desc">
              {requiredTimeLabel}{bookingOption.minutes}{minuteLabel} ・ {formatPrice(bookingOption)}
            </div>
          </div>
          <i className="fa fa-angle-right" />
        </a>
      ))}

      {newBookingOptionPath && (
        <div className="margin-around centerize hidden-xs">
          <a className="btn btn-yellow" href={newBookingOptionPath}>
            <i className="fa fa-plus" /> Add more
          </a>
        </div>
      )}
    </div>
  );
}

BookingOptionsIndex.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  newBookingOptionPath: PropTypes.string,
  lineKeywordPath: PropTypes.string,
  requiredTimeLabel: PropTypes.string.isRequired,
  minuteLabel: PropTypes.string.isRequired,
};
