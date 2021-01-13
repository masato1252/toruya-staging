"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";

const CompanyInfoStep = ({next, prev, step}) => {
  const { props, selected_booking_page, dispatch } = useGlobalContext()

  return (
    <div className="form settings-flow">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize">サービス名どの店舗として提供しますか？</h3>

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

export default CompanyInfoStep
