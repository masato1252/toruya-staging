"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";

const FinalStep = ({step}) => {
  const { online_service_slug } = useGlobalContext()

  return (
    <div className="form settings-flow">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.online_service_creation.create_sale_page")}</h3>

      <div className="action-block">
        <h4 className="margin-around">{I18n.t("user_bot.dashboards.booking_page_creation.create_a_sale_page")}</h4>

        <a href={Routes.new_lines_user_bot_sales_online_service_url({slug: online_service_slug})} className="btn btn-yellow btn-flexible">
          <i className="fa fa-cart-arrow-down fa-4x"></i>
          <h4>{I18n.t("user_bot.dashboards.booking_page_creation.create_a_sale_page_btn")}</h4>
        </a>
      </div>
    </div>
  )
}

export default FinalStep
