"use strict";

import React from "react";

import { useGlobalContext } from "../context/global_state";
import FlowStepIndicator from "../flow_step_indicator";

const PdfContentSetup = ({next, step}) => {
  const { dispatch, content_url } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <FlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.online_service_creation.what_is_pdf_url")}</h3>
      <input
        placeholder={I18n.t("user_bot.dashboards.online_service_creation.what_is_pdf_url")}
        value={content_url || ""}
        onChange={(event) =>
            dispatch({
              type: "SET_ATTRIBUTE",
              payload: {
                attribute: "content_url",
                value: event.target.value
              }
            })
        }
        type="text"
        className="extend with-border"
      />
      <p className="margin-around text-align-left">
        <div dangerouslySetInnerHTML={{__html: I18n.t("user_bot.dashboards.online_service_creation.pdf_hint_html")}} />
      </p>

      {content_url && (
        <div className="action-block">
          <button onClick={next} className="btn btn-yellow" disabled={false}>
            {I18n.t("action.next_step")}
          </button>
        </div>
      )}
    </div>
  )
}

export default PdfContentSetup
