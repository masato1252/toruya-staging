"use strict";

import React, { useEffect } from "react";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";

const LineMessageStep = ({next, prev, step}) => {
  const { props, dispatch, selected_goal } = useGlobalContext()
  const selected_goal_option = props.service_goals.find((goal) => goal.key === selected_goal)

  useEffect(() => {
    if (selected_goal_option.skip_line_message_step_on_creation) next()
  }, [])

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize">{'Line Message'}</h3>

      <div className="action-block">
        <button onClick={next} className="btn btn-yellow" disabled={false}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default LineMessageStep
