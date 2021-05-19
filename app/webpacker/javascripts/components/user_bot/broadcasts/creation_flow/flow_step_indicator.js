"use strict";

import React from "react";
import FlowStepIndicator from "shared/flow_controller/flow_step_indicator";

const StepIndicator = ({step}) => {
  return (
    <FlowStepIndicator
      steps={[
        {icon: "fa-users", wording: I18n.t("user_bot.dashboards.service_creation.content_step"), steps: [0, 1]},
        {icon: "fa-comment", wording: I18n.t("user_bot.dashboards.service_creation.time_step"), steps: [2]},
        {icon: "fa-calendar-alt", wording: I18n.t("user_bot.dashboards.service_creation.upsell_step"), steps: [3]}
      ]}
      current_step={step}
    />
  )
}

export default StepIndicator
