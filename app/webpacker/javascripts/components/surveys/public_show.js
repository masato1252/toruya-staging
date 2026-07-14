import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import axios from "axios";
import { compatRead } from "../../libraries/compat_api";
import SurveyForm from "components/shared/survey/form";

function applyMetaTags(meta) {
  if (!meta) return;
  if (meta.title) document.title = meta.title;
  [
    ["meta[name='description']", "name", "description", meta.description],
    ["meta[property='og:title']", "property", "og:title", meta.title],
    ["meta[property='og:description']", "property", "og:description", meta.description],
  ].forEach(([selector, attribute, key, content]) => {
    if (!content) return;
    let node = document.head.querySelector(selector);
    if (!node) {
      node = document.createElement("meta");
      node.setAttribute(attribute, key);
      document.head.appendChild(node);
    }
    node.setAttribute("content", content);
  });
}

export default function PublicSurveyShow({ slug, labels, lineIdentificationPath, customerId }) {
  const [survey, setSurvey] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [submitted, setSubmitted] = useState(false);

  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/surveys/${slug}/page_context`)
      .then((body) => {
        if (cancelled) return;
        setSurvey(body.data || null);
        applyMetaTags(body.data?.meta);
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

  const handleSubmit = async (surveyAnswers) => {
    if (submitting) return;
    if (!customerId) {
      setError(labels.loginRequired || "LINE login is required before submitting.");
      return;
    }

    setSubmitting(true);
    setError(null);
    try {
      await axios.post(`/surveys/${slug}`, {
        customer_id: customerId,
        survey_answers: surveyAnswers,
      });
      setSubmitted(true);
    } catch (err) {
      const message =
        err.response?.data?.error_message ||
        err.response?.data?.errors?.message ||
        err.message;
      setError(message);
    } finally {
      setSubmitting(false);
    }
  };

  if (submitted) {
    return (
      <div className="container margin-around">
        <p>{labels.thankYou || "Thank you for your response."}</p>
      </div>
    );
  }

  const legacySurvey = {
    ...survey,
    title: survey.name,
    questions: (survey.questions || []).map((question, index) => ({
      ...question,
      description: question.title || question.description || "",
      position: question.position ?? index,
      options: (question.options || []).map((option, optionIndex) => ({
        ...option,
        position: option.position ?? optionIndex,
      })),
    })),
  };

  return (
    <div className="container margin-around">
      {lineIdentificationPath && (
        <p className="margin-around">
          <a className="btn btn-tarco" href={lineIdentificationPath}>
            {labels.lineLogin || "LINE login"}
          </a>
        </p>
      )}
      {!legacySurvey.questions.length ? (
        <p>{labels.noQuestions}</p>
      ) : (
        <SurveyForm
          survey={legacySurvey}
          onSubmit={handleSubmit}
          submit_text={submitting ? (labels.submitting || "Submitting...") : (labels.submit || "Submit")}
        />
      )}
    </div>
  );
}

PublicSurveyShow.propTypes = {
  slug: PropTypes.string.isRequired,
  labels: PropTypes.object.isRequired,
  lineIdentificationPath: PropTypes.string,
  customerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
};
