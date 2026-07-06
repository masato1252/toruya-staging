import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../libraries/compat_api";

export default function PublicOnlineServiceGuestBootstrap({ slug, episodeId }) {
  const [ctx, setCtx] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    const path = episodeId
      ? `/online_services/${slug}/page_context?episode_id=${episodeId}`
      : `/online_services/${slug}/page_context`;
    compatRead(path)
      .then((body) => {
        if (cancelled) return;
        setCtx(body.data || body);
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
  }, [slug, episodeId]);

  if (loading) return <p className="margin-around centerize">Loading...</p>;
  if (error) return <p className="danger margin-around">{error}</p>;
  if (!ctx) return null;

  const episode = ctx.includes?.episode;

  return (
    <div className="online-service-guest-bootstrap container margin-around">
      <h1>{ctx.name}</h1>
      {episode?.name && <h2>{episode.name}</h2>}
      {ctx.note && <p className="note">{ctx.note}</p>}
      <p className="text-muted">Please sign in to access this service.</p>
    </div>
  );
}

PublicOnlineServiceGuestBootstrap.propTypes = {
  slug: PropTypes.string.isRequired,
  episodeId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
};
