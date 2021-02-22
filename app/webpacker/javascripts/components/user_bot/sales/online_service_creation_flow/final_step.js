"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";
import { UrlCopyBtn } from "shared/components";

const FinalStep = ({next, step}) => {
  const { sale_page_id } = useGlobalContext()

  return (
    <div className="form">
      <SalesFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.sales.booking_page_creation.share_sale_page")}</h3>
      <div className="action-block">
        <UrlCopyBtn url={Routes.sale_page_url(sale_page_id || 0)} />
      </div>
    </div>
  )
}

export default FinalStep
