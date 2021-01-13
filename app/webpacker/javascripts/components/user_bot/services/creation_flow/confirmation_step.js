"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";

const ConfirmationStep = ({next, prev, jump, step}) => {
  const { props, dispatch } = useGlobalContext()

  return (
    <div className="form settings-flow">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize">以下のサービスを作成してよろしいですか？</h3>

      <div className="action-block">
        <button onClick={prev} className="btn btn-yellow" disabled={false}>
          {I18n.t("action.prev_step")}
        </button>
        <button onClick={next} className="btn btn-yellow" disabled={false}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default ConfirmationStep
