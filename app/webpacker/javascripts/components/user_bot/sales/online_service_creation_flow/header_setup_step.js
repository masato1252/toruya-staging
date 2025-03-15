"use strict";

import React, { useState, useEffect } from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";
import SaleTemplateContainer from "components/user_bot/sales/booking_pages/sale_template_container";
import { Template, HintTitle } from "shared/builders"

const HeaderSetupStep = ({step, next, prev, jumpByKey}) => {
  const [submitting, setSubmitting] = useState(false)
  const [focus_field, setFocusField] = useState()
  const { initial, selected_online_service, selected_template, dispatch, template_variables, isHeaderSetup, createDraftSalesOnlineServicePage, props } = useGlobalContext()

  useEffect(() => {
    if (initial && isHeaderSetup()) {
      next()
    }
  }, [])

  return (
    <div className="form settings-flow">
      <SalesFlowStepIndicator step={step} />
      <div className="margin-around centerize warning">
        <div dangerouslySetInnerHTML={{__html: I18n.t("user_bot.dashboards.sales.online_service_creation.header_setup_step_hint_html")}} />
      </div>
      <HintTitle template={selected_template.edit_body} focus_field={focus_field} />

      <SaleTemplateContainer
        shop={selected_online_service.company_info}
        product={selected_online_service}>
        <Template
          {...template_variables}
          template={selected_template.edit_body}
          product_name={selected_online_service.product_name}
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
        <button onClick={() => {
          if (props.sale_templates.length > 1) {
            jumpByKey("header_template_selection_step")
          }
          else {
            jumpByKey("selling_number_step")
          }
        }} className="btn btn-tarco">
          {I18n.t("action.prev_step")}
        </button>
        <button
          className="btn btn-gray"
          disabled={submitting}
          onClick={async () => {
            if (submitting) return;
            setSubmitting(true)
            await createDraftSalesOnlineServicePage()
          }}>
          {submitting ? (
            <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
          ) : (
            I18n.t("action.save_as_draft")
          )}
        </button>
        <button
          onClick={next}
          className="btn btn-yellow"
          disabled={!isHeaderSetup()}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )
}

export default HeaderSetupStep
