import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";
import ChatChannels from "components/management/chats";

export default function AdminChatsBootstrap({
  socialServiceUserId,
  userId,
  chatProps,
}) {
  const [socialCustomer, setSocialCustomer] = useState(chatProps?.social_customer || null);
  const [loading, setLoading] = useState(!!(socialServiceUserId || userId));
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!socialServiceUserId && !userId) return undefined;

    let cancelled = false;
    const params = new URLSearchParams();
    if (socialServiceUserId) params.set("social_service_user_id", socialServiceUserId);
    if (userId) params.set("user_id", String(userId));

    compatRead(`/admin/chats/page_context?${params.toString()}`)
      .then((body) => {
        if (cancelled) return;
        setSocialCustomer(body.data?.social_customer ?? null);
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
  }, [socialServiceUserId, userId]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;

  return <ChatChannels {...chatProps} social_customer={socialCustomer} />;
}

AdminChatsBootstrap.propTypes = {
  socialServiceUserId: PropTypes.string,
  userId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  chatProps: PropTypes.object.isRequired,
};
