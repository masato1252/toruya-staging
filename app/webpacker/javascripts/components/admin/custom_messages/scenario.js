import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function AdminCustomMessageScenario({ scenario, locale, newMessageHref, addMoreLabel }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/admin/custom_messages/${encodeURIComponent(scenario)}?locale=${encodeURIComponent(locale)}`)
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
  }, [scenario, locale]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;

  return (
    <>
      <h1>Scenario: {scenario.replace(/_/g, " ")}</h1>
      <ul>
        {items.map((message) => (
          <li key={message.id}>
            <a href={message.edit_href}>{message.title}</a>
          </li>
        ))}
      </ul>
      <div className="margin-around">
        <a href={newMessageHref} className="btn btn-yellow btn-save btn-tweak">
          <i className="fas fa-plus fa-2x" />
          <div className="word">{addMoreLabel}</div>
        </a>
      </div>
    </>
  );
}

AdminCustomMessageScenario.propTypes = {
  scenario: PropTypes.string.isRequired,
  locale: PropTypes.string.isRequired,
  newMessageHref: PropTypes.string.isRequired,
  addMoreLabel: PropTypes.string.isRequired,
};
