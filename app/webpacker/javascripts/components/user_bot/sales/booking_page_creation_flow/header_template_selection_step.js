"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";
import SaleTemplateContainer from "components/user_bot/sales/booking_pages/sale_template_container";
import { Template, HintTitle } from "shared/builders"

const HeaderTemplateSelectionStep = ({step, next, prev}) => {
  const { props, selected_booking_page, selected_template, dispatch, template_variables, focus_field } = useGlobalContext()

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
            template_id={template.id}
          >
            <Template
              template={template.edit_body}
              inputDisabled={true}
              product_name={selected_booking_page.name}
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
    </div>
  )
}

export default HeaderTemplateSelectionStep
