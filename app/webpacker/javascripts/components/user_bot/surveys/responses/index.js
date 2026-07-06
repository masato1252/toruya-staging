import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../../libraries/compat_api";

export default function SurveyResponsesIndex({ businessOwnerId, surveyId, surveyPath, labels }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/lines/user_bot/owner/${businessOwnerId}/surveys/${surveyId}/responses`)
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
  }, [businessOwnerId, surveyId]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;

  return (
    <div className="booking-pages-list">
      {items.map((response) => (
        <div className="field-row with-next-arrow" key={response.id}>
          <a
            className="w-8-12"
            href={`${surveyPath}/responses/${response.id}`}
          >
            <h3 className="text-gray-700 underline">{response.owner_name}</h3>
            <div className="text-gray-500 text-14px">{response.answer_preview}</div>
          </a>
        </div>
      ))}
      {!items.length && <p className="margin-around">{labels.empty}</p>}
    </div>
  );
}

SurveyResponsesIndex.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  surveyId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  surveyPath: PropTypes.string.isRequired,
  labels: PropTypes.object.isRequired,
};
