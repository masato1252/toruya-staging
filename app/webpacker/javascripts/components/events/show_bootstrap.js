import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../libraries/compat_api";
import EventsShow from "./show";

function applyMetaTags(meta) {
  if (!meta) return;
  if (meta.og_title) document.title = meta.og_title;
  [
    ["meta[property='og:title']", "og:title", meta.og_title],
    ["meta[property='og:description']", "og:description", meta.og_description],
  ].forEach(([selector, property, content]) => {
    if (!content) return;
    let node = document.head.querySelector(selector);
    if (!node) {
      node = document.createElement("meta");
      node.setAttribute("property", property);
      document.head.appendChild(node);
    }
    node.setAttribute("content", content);
  });
}

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
    const query = currentEventLineUserId
      ? `?event_line_user_id=${encodeURIComponent(currentEventLineUserId)}`
      : "";
    compatRead(`/events/${encodeURIComponent(eventSlug)}/page_context${query}`)
      .then((body) => {
        if (cancelled) return;
        const payload = body.data || null;
        if (payload) {
          if (currentEventLineUserId) {
            payload.current_event_line_user_id = currentEventLineUserId;
          }
          applyMetaTags(payload.meta);
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
