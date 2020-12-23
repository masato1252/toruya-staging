"use strict";

import React from "react";
import FlowStepIndicator from "shared/flow_controller/flow_step_indicator";

const BookingFlowStepIndicator = ({step}) => {
  return (
    <FlowStepIndicator
      steps={[
        {icon: "fa-home", wording: "Page"},
        {icon: "fa-tags", wording: "Content", steps: [1, 2, 3, 4, 5]},
        {icon: "fa-check", wording: "Done", steps: [6]}
      ]}
      current_step={step}
    />
  )
}

export default BookingFlowStepIndicator
