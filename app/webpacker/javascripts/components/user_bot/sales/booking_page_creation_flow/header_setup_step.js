"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
  import SalesFlowStepIndicator from "./sales_flow_step_indicator";
import { EditTemplate, HintTitle } from "shared/builders"

const HeaderSetupStep = ({step, next, prev}) => {
  const { props, selected_booking_page, dispatch, template_variables, focus_field } = useGlobalContext()

  return (
    <div className="form">
      <SalesFlowStepIndicator step={step} />

      <HintTitle focus_field={focus_field} />
      <EditTemplate
        {...template_variables}
        product_name={selected_booking_page?.name}
        onBlur={(name, value) => {
          dispatch({
            type: "SET_TEMPLATE_VARIABLES",
            payload: {
              attribute: name,
              value: value
            }
          })
        }}
        onFocus={(name) => {
          dispatch({
            type: "SET_ATTRIBUTE",
            payload: {
              attribute: "focus_field",
              value: name
            }
          })
        }}
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

export default HeaderSetupStep
