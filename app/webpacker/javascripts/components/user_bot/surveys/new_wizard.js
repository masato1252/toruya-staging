import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";
import SurveyBuilder from "components/shared/survey/builder";
import { CommonServices } from "user_bot/api";

export default function SurveysNewWizard({ props: initialProps }) {
  const [readyProps, setReadyProps] = useState(
    initialProps.pageContextPath ? null : initialProps,
  );
  const [loadError, setLoadError] = useState(null);

  useEffect(() => {
    if (!initialProps.pageContextPath) return undefined;

    let cancelled = false;
    compatRead(initialProps.pageContextPath)
      .then((body) => {
        if (cancelled) return;
        const form = body.data?.edit_form || body.data;
        if (!form) {
          setLoadError("Failed to load survey creation form");
          return;
        }
        setReadyProps({ ...initialProps, ...form });
      })
      .catch((err) => {
        if (!cancelled) setLoadError(err.message);
      });

    return () => {
      cancelled = true;
    };
  }, [initialProps]);

  const props = readyProps;

  if (loadError) return <p className="danger">{loadError}</p>;
  if (!props) return <p>{I18n.t("common.processing")}</p>;

  const onSubmit = async (surveyData) => {
    const [error, response] = await CommonServices.create({
      url: Routes.lines_user_bot_surveys_path(props.business_owner_id, { format: "json" }),
      data: surveyData,
    });

    if (error) {
      toastr.error(error.response?.data?.error_message || "エラーが発生しました");
    } else if (response?.data?.redirect_to) {
      window.location = response.data.redirect_to;
    }
  };

  return (
    <SurveyBuilder
      onSubmit={onSubmit}
      business_owner_id={props.business_owner_id}
      currency={props.currency || "JPY"}
      mode={props.mode || "survey"}
    />
  );
}

SurveysNewWizard.propTypes = {
  props: PropTypes.shape({
    business_owner_id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
    pageContextPath: PropTypes.string,
    mode: PropTypes.string,
    currency: PropTypes.string,
  }).isRequired,
};
