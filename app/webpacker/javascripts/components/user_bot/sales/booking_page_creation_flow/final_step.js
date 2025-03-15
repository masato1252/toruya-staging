"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";

const FinalStep = ({step}) => {
  const { sale_page_id, props } = useGlobalContext()

  return (
    <div className="form">
      <SalesFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.sales.booking_page_creation.share_sale_page")}</h3>
      <div className="action-block">
        <a
          className="btn btn-tarco"
          target="_blank"
          href={Routes.sale_page_url(sale_page_id || 0)}>
          {I18n.t("action.open_sale_page")}
        </a>
      </div>
      <div className="action-block">
        <a
          className="btn btn-tarco"
          href={Routes.lines_user_bot_sale_path(props.business_owner_id, sale_page_id || 0)}>
          {I18n.t("user_bot.dashboards.sales.booking_page_creation.edit_sale_page")}
        </a>
      </div>
    </div>
  )
}

export default FinalStep;
