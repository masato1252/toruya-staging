import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../../libraries/compat_api";

const LEVEL_LABELS = {
  employee: "スタッフ",
  admin: "管理者",
  owner: "オーナー",
};

export default function StaffsIndex({ businessOwnerId }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;

    compatRead(`/lines/user_bot/owner/${businessOwnerId}/settings/staffs`)
      .then((body) => {
        if (cancelled) return;
        setItems(body.data || []);
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

  return (
    <>
      {items.map((staff) => (
        <a
          key={staff.id}
          className={`field-row field-state-${staff.state}`}
          href={`/lines/user_bot/owner/${businessOwnerId}/settings/staffs/${staff.id}`}
        >
          <div className="dotdotdot">
            <h3>{staff.display_name}</h3>
            <div className="desc">{LEVEL_LABELS[staff.level] || staff.level}</div>
          </div>
          <i className="fa fa-angle-right" />
        </a>
      ))}
    </>
  );
}

StaffsIndex.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
};
