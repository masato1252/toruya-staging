import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function AdminCustomMessageScenarios({ locale }) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/admin/custom_messages/scenarios?locale=${encodeURIComponent(locale)}`)
      .then((body) => {
        if (cancelled) return;
        setData(body.data || null);
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
  }, [locale]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;

  return (
    <>
      <h1>Scenarios</h1>
      <ul>
        {(data?.normal_scenarios || []).map((item) => (
          <li key={item.scenario}>
            <a href={item.href}>{item.label}</a>
          </li>
        ))}
      </ul>
      <br />
      <h2>Health Check</h2>
      <ul>
        {(data?.health_check_scenarios || []).map((item) => (
          <li key={item.scenario}>
            <a href={item.href}>{item.label}</a>
          </li>
        ))}
      </ul>
      <hr style={{ margin: "32px 0" }} />
      <h2>一括メッセージ送信</h2>
      <ul>
        {(data?.bulk_send_links || []).map((item) => (
          <li key={item.bulk_type}>
            <a href={item.href}>{item.label}</a>
          </li>
        ))}
      </ul>
    </>
  );
}

AdminCustomMessageScenarios.propTypes = {
  locale: PropTypes.string.isRequired,
};
