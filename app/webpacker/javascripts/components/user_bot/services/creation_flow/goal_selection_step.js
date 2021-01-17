"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";

const GoalSelectionStep = ({next, step}) => {
  const { props, dispatch } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize">このサービスの目的は何ですか？</h3>
      {props.service_goals.filter(goal => goal.enabled).map((goal) => {
        return (
          <button
            onClick={() => {
              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "selected_goal",
                  value: goal.key
                }
              })

              next()
            }}
            className="btn btn-tarco btn-extend btn-flexible margin-around"
            key={goal.key}>
            <h4>{goal.name}</h4>
            <p className="break-line-content">
              {goal.description}
            </p>
          </button>
        )
      })}

      <div className="action-block">
        <button onClick={next} className="btn btn-yellow" disabled={false}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default GoalSelectionStep
