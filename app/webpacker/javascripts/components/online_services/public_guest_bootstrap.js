import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../libraries/compat_api";

export default function PublicOnlineServiceGuestBootstrap({ slug, episodeId, lineLoginPath }) {
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
        setCtx({ data: body.data, includes: body.includes || {} });
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
  if (!ctx?.data) return null;

  const { data, includes } = ctx;
  const hash = data.online_service_hash || {};
  const companyName = hash.company_info?.name;
  const episode = includes.episode;
  const addFriendUrl = includes.social_account_add_friend_url;

  return (
    <div className="booking-content">
      <div className="header border-0 border-b border-solid border-gray-500">
        <div className="header-title-part">
          {companyName ? <h2>{companyName}</h2> : null}
        </div>
      </div>
      <div className="done-view">
        <h2 className="title">{data.name}</h2>
        {episode?.name && <h3 className="desc">{episode.name}</h3>}
        <h3 className="reminder-mark desc">Login required</h3>
        {data.note && <div className="message break-line-content centerize">{data.note}</div>}

        {lineLoginPath && (
          <div className="message centerize">
            <a href={lineLoginPath} className="btn line-button with-wording with-logo">
              LINE Login
            </a>
          </div>
        )}

        {addFriendUrl && (
          <div className="message centerize">
            <a href={addFriendUrl} className="btn line-button with-wording with-logo">
              Add friend
            </a>
          </div>
        )}
      </div>
    </div>
  );
}

PublicOnlineServiceGuestBootstrap.propTypes = {
  slug: PropTypes.string.isRequired,
  episodeId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  lineLoginPath: PropTypes.string,
};
