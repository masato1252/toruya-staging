import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import axios from "axios";
import { compatRead } from "../../libraries/compat_api";

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

function QuestionField({ question, value, onChange }) {
  const label = (
    <>
      {question.title}
      {question.required && <span className="text-danger"> *</span>}
    </>
  );

  if (question.question_type === "text" || question.question_type === "textarea") {
    const Tag = question.question_type === "textarea" ? "textarea" : "input";
    return (
      <div className="field-row margin-around">
        <label className="block mb-2">{label}</label>
        <Tag
          className="extend"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          required={question.required}
        />
      </div>
    );
  }

  if (question.question_type === "single_selection") {
    return (
      <fieldset className="field-row margin-around">
        <legend>{label}</legend>
        {(question.options || []).map((option) => (
          <label key={option.id} className="block mb-2">
            <input
              type="radio"
              name={`survey-question-${question.id}`}
              value={option.id}
              checked={String(value || "") === String(option.id)}
              onChange={(e) => onChange(e.target.value)}
              required={question.required}
            />{" "}
            {option.content}
          </label>
        ))}
      </fieldset>
    );
  }

  if (question.question_type === "multiple_selection") {
    const selected = Array.isArray(value) ? value.map(String) : [];
    return (
      <fieldset className="field-row margin-around">
        <legend>{label}</legend>
        {(question.options || []).map((option) => (
          <label key={option.id} className="block mb-2">
            <input
              type="checkbox"
              value={option.id}
              checked={selected.includes(String(option.id))}
              onChange={(e) => {
                const id = String(option.id);
                onChange(e.target.checked ? [...selected, id] : selected.filter((item) => item !== id));
              }}
            />{" "}
            {option.content}
          </label>
        ))}
      </fieldset>
    );
  }

  return (
    <div className="field-row margin-around">
      <label className="block mb-2">{label}</label>
      <input
        className="extend"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        required={question.required}
      />
    </div>
  );
}

QuestionField.propTypes = {
  question: PropTypes.object.isRequired,
  value: PropTypes.oneOfType([PropTypes.string, PropTypes.array]),
  onChange: PropTypes.func.isRequired,
};

export default function PublicSurveyShow({ slug, labels, lineIdentificationPath, customerId }) {
  const [survey, setSurvey] = useState(null);
  const [answers, setAnswers] = useState({});
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

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!customerId) {
      setError(labels.loginRequired || "LINE login is required before submitting.");
      return;
    }

    setSubmitting(true);
    setError(null);
    try {
      const surveyAnswers = Object.entries(answers).map(([questionId, value]) => {
        const question = survey.questions.find((item) => String(item.id) === String(questionId));
        const selection =
          question?.question_type === "single_selection" ||
          question?.question_type === "multiple_selection";
        return {
          survey_question_id: Number(questionId),
          text_answer: selection ? null : value,
          survey_option_ids: selection
            ? (Array.isArray(value) ? value : [value]).map(Number)
            : [],
        };
      });
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

  return (
    <div className="container margin-around">
      <h1>{survey.name}</h1>
      {survey.description && <p>{survey.description}</p>}
      {lineIdentificationPath && (
        <p className="margin-around">
          <a className="btn btn-tarco" href={lineIdentificationPath}>
            {labels.lineLogin || "LINE login"}
          </a>
        </p>
      )}
      <form onSubmit={handleSubmit} className="survey-questions">
        {(survey.questions || []).map((q) => (
          <QuestionField
            key={q.id}
            question={q}
            value={answers[q.id] || ""}
            onChange={(val) => setAnswers((prev) => ({ ...prev, [q.id]: val }))}
          />
        ))}
        {!survey.questions?.length && <p>{labels.noQuestions}</p>}
        {survey.questions?.length > 0 && (
          <div className="margin-around">
            <button type="submit" className="btn btn-yellow" disabled={submitting}>
              {submitting ? (labels.submitting || "Submitting...") : (labels.submit || "Submit")}
            </button>
          </div>
        )}
      </form>
    </div>
  );
}

PublicSurveyShow.propTypes = {
  slug: PropTypes.string.isRequired,
  labels: PropTypes.object.isRequired,
  lineIdentificationPath: PropTypes.string,
  customerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
};
