"use strict";

import React, { useEffect } from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";
import SaleTemplateContainer from "components/user_bot/sales/booking_pages/sale_template_container";
import { Template } from "shared/builders"

const HeaderTemplateSelectionStep = ({step, next, prev}) => {
  const { props, initial, selected_booking_page, selected_template, dispatch } = useGlobalContext()

  useEffect(() => {
    if (initial && selected_template) {
      next()
    }
    else if (props.sale_templates.length === 1) {
      dispatch({
        type: "SET_ATTRIBUTE",
        payload: {
          attribute: "selected_template",
          value: props.sale_templates[0]
        }
      })
      next()
    }
  }, [])

  return (
    <div className="form">
      <SalesFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.sales.booking_page_creation.select_header_template")}</h3>
      {props.sale_templates.map(template => {
        return (
          <SaleTemplateContainer
            shop={props.shops[selected_booking_page.shop_id]}
            product={selected_booking_page}
            key={`template-${template.id}`}
            template_id={template.position}
            support_feature_flags={props.support_feature_flags}
          >
            <Template
              template={template.edit_body}
              inputDisabled={true}
              product_name={selected_booking_page.product_name}
              onClick={() => {
                console.log(template)

                dispatch({
                  type: "SET_ATTRIBUTE",
                  payload: {
                    attribute: "selected_template",
                    value: template
                  }
                })

                next()
              }}
            />
          </SaleTemplateContainer>
        )
      })}
      <div className="action-block">
        <button onClick={prev} className="btn btn-tarco">
          {I18n.t("action.prev_step")}
        </button>
      </div>
    </div>
  )
}

export default HeaderTemplateSelectionStep
