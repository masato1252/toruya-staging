"use strict";

import React from "react";
import FlowStepIndicator from "shared/flow_controller/flow_step_indicator";

const ServiceFlowStepIndicator = ({step, step_key}) => {
  return (
    <FlowStepIndicator
      steps={[
        {icon: "fa-flag", wording: I18n.t("user_bot.dashboards.service_creation.goal_step"), steps: ["goal_step"]},
        {
          icon: "fa-file-alt",
          wording: I18n.t("user_bot.dashboards.service_creation.content_step"),
          steps: ["solution_step", "name_step", "company_step"]
        },
        {icon: "fa-hourglass-half", wording: I18n.t("user_bot.dashboards.service_creation.time_step"), steps: ["endtime_step"]},
        {icon: "fa-cart-plus", wording: I18n.t("user_bot.dashboards.service_creation.upsell_step"), steps: ["upsell_step"]},
        {icon: "fa-check", wording: I18n.t("user_bot.dashboards.service_creation.check_step"), steps: ["confirmation_step"]},
        {steps: ["final_step"]}
      ]}
      current_step={step}
      current_step_key={step_key}
    />
  )
}

export default ServiceFlowStepIndicator
