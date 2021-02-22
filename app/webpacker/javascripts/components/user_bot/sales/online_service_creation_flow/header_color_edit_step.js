"use strict";

import React from "react";
import _ from "lodash";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";
import SaleTemplateContainer from "components/user_bot/sales/booking_pages/sale_template_container";
import { Template, HintTitle, WordColorPickers } from "shared/builders"

const HeaderColorEditStep= ({step, next, prev, jump}) => {
  const { props, selected_online_service, selected_template, dispatch, template_variables, isReadyForPreview } = useGlobalContext()

  return (
    <div className="form settings-flow">
      <SalesFlowStepIndicator step={step} />
      <h4 className="header centerize"
        dangerouslySetInnerHTML={{ __html: I18n.t("user_bot.dashboards.sales.booking_page_creation.select_color_html") }} />

      <SaleTemplateContainer
        shop={selected_online_service.company_info}
        product={selected_online_service}>
        <Template
          template={selected_template.view_body}
          {...(_.merge(selected_online_service.company_info.template_variables, template_variables))}
          product_name={selected_online_service?.product_name}
        />
      </SaleTemplateContainer>
      <div className="centerize">
        <WordColorPickers
          template={selected_template.view_body}
          {...(_.merge(selected_online_service.company_info.template_variables, template_variables))}
          onChange={(name, value) => {
            dispatch({
              type: "SET_TEMPLATE_VARIABLES",
              payload: {
                attribute: name,
                value: value
              }
            })
          }}
        />
      </div>
      <div className="action-block">
        {I18n.t("user_bot.dashboards.sales.booking_page_creation.color_tip")}
      </div>
      <div className="action-block">
        <button onClick={prev} className="btn btn-tarco">
          {I18n.t("action.prev_step")}
        </button>
        <button onClick={() => {(isReadyForPreview()) ? jump(11) : next()}} className="btn btn-yellow">
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default HeaderColorEditStep
