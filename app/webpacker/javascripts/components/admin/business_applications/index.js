import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function AdminBusinessApplicationsIndex({ title }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead("/admin/business_applications")
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
  }, []);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;

  return (
    <>
      <h1>{title}</h1>
      <ul>
        {items.map((item) => (
          <li key={item.id}>
            {item.user_name} {item.user_email} {new Date(item.updated_at).toLocaleString()}
            {item.state === "pending" ? (
              <>
                {" "}
                <a href={item.approve_href} className="btn btn-success" data-method="post">
                  Approve
                </a>{" "}
                <a href={item.reject_href} className="btn btn-danger" data-method="post" data-confirm="Are you sure?">
                  Reject
                </a>
              </>
            ) : null}
          </li>
        ))}
      </ul>
    </>
  );
}

AdminBusinessApplicationsIndex.propTypes = {
  title: PropTypes.string.isRequired,
};
