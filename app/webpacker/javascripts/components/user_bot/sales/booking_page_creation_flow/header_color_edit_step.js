"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";
import { ViewTemplate, HintTitle } from "shared/builders"

const HeaderColorEditStep= ({step, next, prev}) => {
  const { props, selected_booking_page, dispatch, template_variables, focus_field } = useGlobalContext()

  return (
    <div className="form">
      <SalesFlowStepIndicator step={step} />
      <ViewTemplate
        {...template_variables}
        product_name={selected_booking_page?.name}
      />
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

export default HeaderColorEditStep
