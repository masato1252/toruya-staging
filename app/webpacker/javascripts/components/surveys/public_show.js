import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../libraries/compat_api";

export default function PublicSurveyShow({ slug, labels }) {
  const [survey, setSurvey] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/surveys/${slug}/page_context`)
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
  }, [slug]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;
  if (!survey) return null;

  return (
    <div className="container">
      <h1>{survey.name}</h1>
      {survey.description && <p>{survey.description}</p>}
      <div className="survey-questions">
        {(survey.questions || []).map((q) => (
          <div key={q.id} className="field-row">
            <strong>{q.title}</strong>
            {q.required && <span className="text-danger"> *</span>}
          </div>
        ))}
      </div>
      {!survey.questions?.length && <p>{labels.noQuestions}</p>}
    </div>
  );
}

PublicSurveyShow.propTypes = {
  slug: PropTypes.string.isRequired,
  labels: PropTypes.object.isRequired,
};
