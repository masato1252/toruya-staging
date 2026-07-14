import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../libraries/compat_api";
import EventContentShow from "./show";

function applyMetaTags(meta) {
  if (!meta) return;
  if (meta.title) document.title = meta.title;
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

export default function EventContentShowBootstrap({
  eventSlug,
  contentId,
  startUsageUrl,
  upsellConsultationUrl,
  monitorApplyUrl,
  trackActivityUrl,
  backUrl,
  lineLoginUrl,
  participationUrl,
  captureRegistrationSourceUrl,
  addFriendUrl,
  currentEventLineUserId,
}) {
  const [props, setProps] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    const query = currentEventLineUserId
      ? `?event_line_user_id=${encodeURIComponent(currentEventLineUserId)}`
      : "";
    compatRead(`/events/${encodeURIComponent(eventSlug)}/contents/${contentId}/page_context${query}`)
      .then((body) => {
        if (cancelled) return;
        const data = body.data || null;
        if (!data?.event_content) {
          setError("コンテンツが見つかりません");
          return;
        }
        applyMetaTags(data.meta);

        const eventContent = {
          ...data.event_content,
        };

        setProps({
          event_content: eventContent,
          event_slug: data.event.slug,
          event_title: data.event.title,
          event_ended: data.event.ended,
          event_not_started: data.event.not_started,
          event_logo_image_url: data.event.logo_image_url,
          start_usage_url: startUsageUrl,
          upsell_consultation_url: upsellConsultationUrl,
          monitor_apply_url: monitorApplyUrl,
          track_activity_url: trackActivityUrl,
          back_url: backUrl,
          line_login_url: lineLoginUrl,
          participation_url: participationUrl,
          capture_registration_source_url: captureRegistrationSourceUrl,
          add_friend_url: addFriendUrl,
          current_event_line_user_id: currentEventLineUserId,
        });
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
  }, [
    eventSlug,
    contentId,
    startUsageUrl,
    upsellConsultationUrl,
    monitorApplyUrl,
    trackActivityUrl,
    backUrl,
    lineLoginUrl,
    participationUrl,
    captureRegistrationSourceUrl,
    addFriendUrl,
    currentEventLineUserId,
  ]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;
  if (!props) return <p>コンテンツが見つかりません</p>;

  return <EventContentShow props={props} />;
}

EventContentShowBootstrap.propTypes = {
  eventSlug: PropTypes.string.isRequired,
  contentId: PropTypes.number.isRequired,
  startUsageUrl: PropTypes.string.isRequired,
  upsellConsultationUrl: PropTypes.string.isRequired,
  monitorApplyUrl: PropTypes.string.isRequired,
  trackActivityUrl: PropTypes.string.isRequired,
  backUrl: PropTypes.string.isRequired,
  lineLoginUrl: PropTypes.string,
  participationUrl: PropTypes.string.isRequired,
  captureRegistrationSourceUrl: PropTypes.string.isRequired,
  addFriendUrl: PropTypes.string,
  currentEventLineUserId: PropTypes.number,
};
