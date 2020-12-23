"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";

const HeaderSetupStep = ({step, next, prev}) => {
  const { props, watch } = useGlobalContext()

  return (
    <div className="form">
      <SalesFlowStepIndicator step={step} />
      Template Selection
      <div className="action-block">
        <button onClick={prev} className="btn btn-tarco">
          {I18n.t("action.prev_step")}
        </button>
        <button onClick={next} className="btn btn-yellow">
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )
}

export default HeaderSetupStep
