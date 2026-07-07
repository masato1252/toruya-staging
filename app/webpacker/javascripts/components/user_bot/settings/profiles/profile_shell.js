import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../../libraries/compat_api";

export default function ProfileShell({ businessOwnerId, labels }) {
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/lines/user_bot/owner/${businessOwnerId}/settings/profile/page_context`)
      .then((body) => {
        if (cancelled) return;
        setProfile(body.data || null);
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

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;
  if (!profile) return null;

  return (
    <>
      <div className="field-header">{labels.name}</div>
      <div className="field-row">{profile.name}</div>

      <div className="field-header">{labels.phoneNumber}</div>
      <div className="field-row">{profile.phone_number || "-"}</div>
    </>
  );
}

ProfileShell.propTypes = {
  businessOwnerId: PropTypes.number.isRequired,
  labels: PropTypes.shape({
    name: PropTypes.string.isRequired,
    phoneNumber: PropTypes.string.isRequired,
  }).isRequired,
};
