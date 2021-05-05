"use strict";

import React, { useState } from "react";

import { useGlobalContext } from "../context/global_state";
import ServiceFlowStepIndicator from "../services_flow_step_indicator";

const VideoContentSetup = ({next, step}) => {
  const { props, dispatch, content } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.online_service_creation.what_is_pdf_url")}</h3>
      <input
        placeholder={I18n.t("user_bot.dashboards.online_service_creation.what_is_pdf_url")}
        value={content?.url || ""}
        onChange={(event) =>
            dispatch({
              type: "SET_ATTRIBUTE",
              payload: {
                attribute: "content",
                value: {
                  url: event.target.value
                }
              }
            })
        }
        type="text"
        className="extend with-border"
      />
      <p className="margin-around text-align-left">
        {I18n.t("user_bot.dashboards.online_service_creation.pdf_hint")}
      </p>

      {content?.url && (
        <div className="action-block">
          <button onClick={next} className="btn btn-yellow" disabled={false}>
            {I18n.t("action.next_step")}
          </button>
        </div>
      )}
    </div>
  )

}

export default VideoContentSetup
