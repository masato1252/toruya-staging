"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";

const FinalStep = ({step}) => {
  return (
    <div className="form">
      <SalesFlowStepIndicator step={step} />
      FinalStep
    </div>
  )
}

export default FinalStep;
