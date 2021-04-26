"use strict";

import React, { useState } from "react";

import { useGlobalContext } from "../context/global_state";
import ServiceFlowStepIndicator from "../services_flow_step_indicator";

const VideoContentSetup = ({next, step}) => {
  const { props, dispatch, content } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize">{"What is pdf provide"}</h3>
      <input
        placeholder={"What is pdf"}
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
        {"pdf hint"}
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
