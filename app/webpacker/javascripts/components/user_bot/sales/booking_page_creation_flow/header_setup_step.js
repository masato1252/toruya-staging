"use strict";

import React, { useState } from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";
import SaleTemplateContainer from "components/user_bot/sales/booking_pages/sale_template_container";
import { Template, HintTitle } from "shared/builders"

const HeaderSetupStep = ({step, next, prev}) => {
  const [focus_field, setFocusField] = useState()
  const { props, selected_booking_page, selected_template, dispatch, template_variables } = useGlobalContext()

  return (
    <div className="form">
      <SalesFlowStepIndicator step={step} />
      <HintTitle template={selected_template.edit_body} focus_field={focus_field} />

      <SaleTemplateContainer
        shop={props.shops[selected_booking_page.shop_id]}
        product={selected_booking_page}>
        <Template
          {...template_variables}
          template={selected_template.edit_body}
          product_name={selected_booking_page.name}
          onBlur={(name, value) => {
            dispatch({
              type: "SET_TEMPLATE_VARIABLES",
              payload: {
                attribute: name,
                value: value
              }
            })
          }}
          onFocus={(name) => setFocusField(name)}
        />
      </SaleTemplateContainer>

      <div className="action-block">
        <button onClick={prev} className="btn btn-tarco">
          {I18n.t("action.prev_step")}
        </button>
        <button
          onClick={next}
          className="btn btn-yellow"
          disabled={!selected_template.edit_body.filter(block => block.component === "input").every(filterBlock => template_variables?.[filterBlock.name] != null)}>
          {I18n.t("action.next_step")}
        </button>
        </div>
    </div>
  )
}

export default HeaderSetupStep
