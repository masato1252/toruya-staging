import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

function formatEventTime(iso) {
  if (!iso) return "";
  const date = new Date(iso);
  return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
}

export default function SchedulesEventsList({ businessOwnerId, startDate, endDate, labels }) {
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    const query = `?schedule_start_date=${startDate}&schedule_end_date=${endDate}`;
    compatRead(`/lines/user_bot/owner/${businessOwnerId}/schedules/events${query}`)
      .then((body) => {
        if (cancelled) return;
        const items = Array.isArray(body) ? body : body.data || [];
        setEvents(items);
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
  }, [businessOwnerId, startDate, endDate]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;
  if (!events.length) {
    return <h3 className="margin-around centerize">{labels.noSchedule}</h3>;
  }

  let lastDate = null;
  return (
    <div className="events">
      {events.map((event, index) => {
        const time = event.time || event.start_time;
        const day = time ? new Date(time).toDateString() : null;
        const showDate = day && day !== lastDate;
        if (showDate) lastDate = day;
        const reservationPath =
          event.type === "reservation" && event.id && event.shop_id
            ? `/lines/user_bot/owner/${businessOwnerId}/shops/${event.shop_id}/reservations/${event.id}`
            : null;

        return (
          <React.Fragment key={`${event.type}-${event.id || index}`}>
            {showDate && (
              <div className="schedule-date">
                {new Date(time).toLocaleDateString()}
              </div>
            )}
            <div className="event-row">
              {reservationPath ? (
                <a className="event" href={reservationPath}>
                  <div className={`state ${event.state || ""}`} />
                  <div className="time">
                    <div className="start-time">{formatEventTime(event.start_time || time)}</div>
                    <div className="start-time">{formatEventTime(event.end_time)}</div>
                  </div>
                  <div className="content">
                    <div className="top">{event.menus_name || event.title}</div>
                    <div className="bottom">{event.customer_names_sentence || event.customer_name}</div>
                  </div>
                  <div className="info">{event.shop_name}</div>
                </a>
              ) : (
                <div className="event">
                  <div className="content">
                    <div className="top">{event.title || event.type}</div>
                  </div>
                </div>
              )}
            </div>
          </React.Fragment>
        );
      })}
    </div>
  );
}

SchedulesEventsList.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  startDate: PropTypes.string.isRequired,
  endDate: PropTypes.string.isRequired,
  labels: PropTypes.object.isRequired,
};
