"use strict";

import React, { useEffect } from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";
import SaleTemplateContainer from "components/user_bot/sales/booking_pages/sale_template_container";
import { Template, HintTitle } from "shared/builders"

const HeaderTemplateSelectionStep = ({next, step}) => {
  const { props, dispatch, selected_online_service } = useGlobalContext()

  return (
    <div className="form settings-flow">
      <SalesFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.sales.booking_page_creation.select_header_template")}</h3>

      {props.sale_templates.map(template => {
        return (
          <SaleTemplateContainer
            shop={selected_online_service.company_info}
            product={selected_online_service}
            key={`template-${template.id}`}
            template_id={template.id}
          >
            <Template
              template={template.edit_body}
              inputDisabled={true}
              product_name={selected_online_service.product_name}
              onClick={() => {
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
