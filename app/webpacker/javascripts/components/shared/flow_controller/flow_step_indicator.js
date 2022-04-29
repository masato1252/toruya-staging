"use strict";

import React from "react";

const FlowStepIndicator = ({steps, current_step, current_step_key}) => {
  let step_status;
  let line_status;

  // If there is current_step_key, used key to get which step we are currently.
  // Otherwise use current_step
  if (current_step_key) {
    steps.forEach((step, index) => {
      if (step.steps && step.steps.includes(current_step_key)) {
        current_step = index;
      }
    })
  }

  // Don't show step if there is no icon
  const steps_with_icon = steps.filter((step) => !!step.icon);

  return (
    <div className="flow-step-indicator">
      {steps_with_icon.map((step, index) => {
        if (index < current_step) step_status = "active"
        else if (index == current_step) step_status = "current"
        else step_status = "inactive"

        if (index + 1 < current_step) line_status = "active"
        else if (index + 1 == current_step) line_status = "current"
        else line_status = "inactive"

        return (
          <React.Fragment key={`step-${index}-${current_step_key}`}>
            <div className="step">
              <i className={`fa ${step_status} ${step.icon}`}></i>
              <div className={`wording ${step_status}`}>{step.wording}</div>
            </div>
            {steps_with_icon.length - 1 != index && <div className={`line ${line_status}`}></div>}
          </React.Fragment>
        )
      })}
    </div>
  )
}

export default FlowStepIndicator
