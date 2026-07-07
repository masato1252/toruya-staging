import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../libraries/compat_api";

export default function PublicOnlineServiceMemberBootstrap({ slug, episodeId, customerId }) {
  const [ctx, setCtx] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    const params = new URLSearchParams();
    if (episodeId) params.set("episode_id", episodeId);
    if (customerId) params.set("customer_id", customerId);
    const suffix = params.toString() ? `?${params.toString()}` : "";
    compatRead(`/online_services/${slug}/page_context${suffix}`)
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
  }, [slug, episodeId, customerId]);

  if (loading) return <p className="margin-around centerize">Loading...</p>;
  if (error) return <p className="danger margin-around">{error}</p>;
  if (!ctx?.data) return null;

  const { data, includes } = ctx;
  const hash = data.online_service_hash || {};
  const member = includes.service_member;

  return (
    <div className="margin-around">
      <h1>{hash.name || data.name}</h1>
      {member && (
        <p className="text-gray-600">
          {member.active ? "Active member" : "Inactive"} · {member.watched_lesson_ids?.length ?? 0} lessons watched
        </p>
      )}
      {Array.isArray(hash.chapters) && hash.chapters.length > 0 && (
        <div className="mt-4">
          <h3>Chapters</h3>
          <ul>
            {hash.chapters.map((chapter) => (
              <li key={chapter.id}>{chapter.name}</li>
            ))}
          </ul>
        </div>
      )}
      {hash.note && <p className="mt-4">{hash.note}</p>}
    </div>
  );
}

PublicOnlineServiceMemberBootstrap.propTypes = {
  slug: PropTypes.string.isRequired,
  episodeId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  customerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
};
