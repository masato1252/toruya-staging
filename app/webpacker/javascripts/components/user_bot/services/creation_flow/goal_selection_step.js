"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";

const GoalSelectionStep = ({next, step}) => {
  const { props, dispatch } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.online_service_creation.what_is_your_goal")}</h3>
      {props.service_goals.map((goal) => {
        return (
          <button
            onClick={() => {
              if (!goal.enabled) return;

              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "selected_goal",
                  value: goal.key
                }
              })

              next()
            }}
            className="btn btn-tarco btn-extend btn-flexible margin-around m10 relative"
            disabled={!goal.enabled}
            key={goal.key}>
            <h4>{goal.name}</h4>
            <p className="break-line-content text-align-left">
              {goal.description}
            </p>
            {!goal.enabled && <span className="preparing">{I18n.t('common.preparing')}</span>}
          </button>
        )
      })}
    </div>
  )

}

export default GoalSelectionStep
