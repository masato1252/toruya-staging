import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function SurveyShow({ businessOwnerId, surveyId, labels }) {
  const [survey, setSurvey] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/lines/user_bot/owner/${businessOwnerId}/surveys/${surveyId}/page_context`)
      .then((body) => {
        if (cancelled) return;
        setSurvey(body.data || null);
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
  if (!survey) return null;

  const base = `/lines/user_bot/owner/${businessOwnerId}/surveys/${surveyId}`;

  return (
    <>
      <div className="field-group-header">{labels.about}</div>
      <a className="field-row" href={`${base}/edit`}>
        <span>{labels.title}: {survey.name}</span>
      </a>
      {survey.description && (
        <div className="field-row">
          <span>{survey.description}</span>
        </div>
      )}
      <div className="field-row">
        <span>{labels.questions}: {survey.question_count ?? 0}</span>
      </div>
      <div className="field-row">
        <span>{labels.status}: {survey.active ? labels.active : labels.inactive}</span>
      </div>
      {survey.public_url_path && (
        <a className="field-row" href={survey.public_url_path} target="_blank" rel="noreferrer">
          <span>{labels.publicUrl}</span>
        </a>
      )}
      <div className="action-block">
        <a className="btn btn-tarco" href={`${base}/edit`}>{labels.edit}</a>
        <a className="btn btn-tarco" href={`${base}/settings`}>{labels.settings}</a>
      </div>
    </>
  );
}

SurveyShow.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  surveyId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  labels: PropTypes.object.isRequired,
};
