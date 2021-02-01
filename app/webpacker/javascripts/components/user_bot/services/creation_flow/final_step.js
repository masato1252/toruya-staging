"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";

const FinalStep = ({step}) => {
  const { props, dispatch } = useGlobalContext()

  return (
    <div className="form settings-flow">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.online_service_creation.create_sale_page")}</h3>
    </div>
  )

}

export default FinalStep
