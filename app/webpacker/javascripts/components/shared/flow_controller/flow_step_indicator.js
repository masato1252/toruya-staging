"use strict";

import React from "react";

const FlowStepIndicator = ({steps, current_step}) => {
  let step_status;
  let line_status;

  return (
    <div className="flow-step-indicator">
      {steps.map((step, index) => {
        if (index < current_step) step_status = "active"
        else if (index == current_step) step_status = "current"
        else step_status = "inactive"

        if (index + 1 < current_step) line_status = "active"
        else if (index + 1 == current_step) line_status = "current"
        else line_status = "inactive"

        return (
          <React.Fragment key={`step-${index}`}>
            <div className="step">
              <i className={`fa ${step_status} ${step.icon}`}></i>
              <div className={`wording ${step_status}`}>{step.wording}</div>
            </div>
            {steps.length - 1 != index && <div className={`line ${line_status}`}></div>}
          </React.Fragment>
        )
      })}
    </div>
  )
}

export default FlowStepIndicator
