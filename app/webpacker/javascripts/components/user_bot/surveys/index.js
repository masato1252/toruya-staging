import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function SurveysIndex({ businessOwnerId, surveyUrlBase, introductionHtml }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/lines/user_bot/owner/${businessOwnerId}/surveys`)
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
    return () => { cancelled = true; };
  }, [businessOwnerId]);

  if (loading) return <div className="booking-pages-list"><p>Loading...</p></div>;
  if (error) return <div className="booking-pages-list danger"><p>{error}</p></div>;

  return (
    <div className="booking-pages-list">
      {items.map((survey) => {
        const publicUrl = survey.slug ? `${surveyUrlBase}/surveys/${survey.slug}` : null;
        return (
          <div className="field-row with-next-arrow" key={survey.id}>
            <a className="w-8-12" href={`/lines/user_bot/owner/${businessOwnerId}/surveys/${survey.id}`}>
              <h3 className="text-gray-700 underline">{survey.name}</h3>
            </a>
            {publicUrl && (
              <div className="w-3-12 flex">
                <button
                  type="button"
                  className="btn btn-icon btn-tarco mr-2"
                  data-clipboard-text={publicUrl}
                  data-controller="clipboard"
                  data-action="clipboard#copy"
                >
                  <i className="far fa-clone" />
                </button>
                <a className="btn btn-icon btn-tarco" href={publicUrl} target="_blank" rel="noreferrer">
                  <i className="fas fa-external-link-alt" />
                </a>
              </div>
            )}
          </div>
        );
      })}
      {introductionHtml && (
        <div className="margin-around centerize" dangerouslySetInnerHTML={{ __html: introductionHtml }} />
      )}
    </div>
  );
}

SurveysIndex.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  surveyUrlBase: PropTypes.string.isRequired,
  introductionHtml: PropTypes.string,
};
