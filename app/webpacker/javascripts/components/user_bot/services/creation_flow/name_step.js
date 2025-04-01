"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";
import { SubmitButton } from "shared/components";

const NameStep = ({next, step, lastStep, step_key}) => {
  const { props, dispatch, name, selected_goal, createService } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} step_key={step_key} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.online_service_creation.what_is_service_name")}</h3>
      <input
        type="text"
        value={name || ""}
        className="extend with-border"
        onChange={(event) =>
            dispatch({
              type: "SET_ATTRIBUTE",
              payload: {
                attribute: "name",
                value: event.target.value
              }
            })
        }
      />

      <div className="action-block">
        {(selected_goal === 'membership' || selected_goal === 'bundler') ? (
          <SubmitButton
            handleSubmit={createService}
            submitCallback={lastStep}
            btnWord={I18n.t("user_bot.dashboards.online_service_creation.create_by_this_setting")}
          />
        ) : (
          <button onClick={next} className="btn btn-yellow" disabled={false}>
            {I18n.t("action.next_step")}
          </button>
        )}
      </div>
    </div>
  )

}

export default NameStep
