"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";

const FinalStep = ({step}) => {
  const { props, dispatch } = useGlobalContext()

  return (
    <div className="form settings-flow">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize">作成したサービスページをシェアしましょう</h3>
    </div>
  )

}

export default FinalStep
