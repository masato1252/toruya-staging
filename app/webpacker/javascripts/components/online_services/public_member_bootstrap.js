import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../libraries/compat_api";
import CoursePage from "user_bot/services/online_service_page/course";
import MembershipPage from "user_bot/services/online_service_page/membership";
import OnlineServicePage from "user_bot/services/online_service_page";

export default function PublicOnlineServiceMemberBootstrap({
  slug,
  episodeId,
  customerId,
  lessonId,
  encryptedCustomerId,
  encryptedSocialServiceUserId,
}) {
  const [ctx, setCtx] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    const params = new URLSearchParams();
    if (episodeId) params.set("episode_id", episodeId);
    if (customerId) params.set("customer_id", customerId);
    if (encryptedCustomerId) params.set("encrypted_customer_id", encryptedCustomerId);
    if (encryptedSocialServiceUserId) {
      params.set("encrypted_social_service_user_id", encryptedSocialServiceUserId);
    }
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
  }, [slug, episodeId, customerId, encryptedCustomerId, encryptedSocialServiceUserId]);

  if (loading) return <p className="margin-around centerize">Loading...</p>;
  if (error) return <p className="danger margin-around">{error}</p>;
  if (!ctx?.data) return null;

  const { data, includes } = ctx;
  const hash = data.online_service_hash || {};
  const member = includes.service_member;
  const watchedLessonIds = member?.watched_lesson_ids || [];
  const goalType = data.goal_type;

  if (goalType === "course" || goalType === "free_course" || goalType === "bundled_course") {
    return (
      <CoursePage
        course={hash}
        lesson_id={lessonId}
        lesson_ids={watchedLessonIds}
        preview={false}
        encrypted_social_service_user_id={encryptedSocialServiceUserId}
      />
    );
  }

  if (goalType === "membership") {
    return (
      <MembershipPage
        membership={{
          ...hash,
          tags: hash.tags || [],
          company_info: hash.company_info || {},
        }}
        default_episode={includes.episode || (hash.episodes && hash.episodes[0]) || null}
        done_episode_ids={member?.watched_episode_ids || []}
        preview={false}
        no_available_episodes={!hash.episodes || hash.episodes.length === 0}
      />
    );
  }

  return <OnlineServicePage {...hash} demo={false} light={false} />;
}

PublicOnlineServiceMemberBootstrap.propTypes = {
  slug: PropTypes.string.isRequired,
  episodeId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  customerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  lessonId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  encryptedCustomerId: PropTypes.string,
  encryptedSocialServiceUserId: PropTypes.string,
};
