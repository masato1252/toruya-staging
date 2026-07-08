import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";
import EventsShow from "./show";

export default function EventsShowBootstrap({
  eventSlug,
  lineLoginUrl,
  addFriendUrl,
  currentEventPath,
  currentEventLineUserId,
}) {
  const [event, setEvent] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/events/${encodeURIComponent(eventSlug)}/page_context`)
      .then((body) => {
        if (cancelled) return;
        const payload = body.data || null;
        if (payload) {
          payload.is_logged_in = Boolean(currentEventLineUserId);
          if (currentEventLineUserId) {
            payload.current_event_line_user_id = currentEventLineUserId;
          }
        }
        setEvent(payload);
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
  }, [eventSlug, currentEventLineUserId]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;
  if (!event) return <p>イベントが見つかりません</p>;

  return (
    <EventsShow
      event={event}
      line_login_url={lineLoginUrl}
      add_friend_url={addFriendUrl}
      current_event_path={currentEventPath}
      current_event_line_user_id={currentEventLineUserId}
    />
  );
}

EventsShowBootstrap.propTypes = {
  eventSlug: PropTypes.string.isRequired,
  lineLoginUrl: PropTypes.string,
  addFriendUrl: PropTypes.string,
  currentEventPath: PropTypes.string,
  currentEventLineUserId: PropTypes.number,
};
