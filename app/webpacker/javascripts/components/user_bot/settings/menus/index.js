import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../../libraries/compat_api";

export default function MenusIndex({ businessOwnerId }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;

    compatRead(`/lines/user_bot/owner/${businessOwnerId}/settings/menus`)
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
      {items.map((menu) => (
        <a
          key={menu.id}
          className="field-row"
          href={`/lines/user_bot/owner/${businessOwnerId}/settings/menus/${menu.id}`}
        >
          <span>{menu.name}</span>
          <i className="fa fa-angle-right" />
        </a>
      ))}
    </>
  );
}

MenusIndex.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
};
