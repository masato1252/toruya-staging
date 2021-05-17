"use strict";

import React from "react";
import FlowStepIndicator from "shared/flow_controller/flow_step_indicator";

const StepIndicator = ({step}) => {
  return (
    <FlowStepIndicator
      steps={[
        {icon: "fa-file-alt", wording: I18n.t("user_bot.dashboards.service_creation.content_step"), steps: [1, 2]},
        {icon: "fa-hourglass-half", wording: I18n.t("user_bot.dashboards.service_creation.time_step"), steps: [3]},
        {icon: "fa-cart-plus", wording: I18n.t("user_bot.dashboards.service_creation.upsell_step"), steps: [4]}
      ]}
      current_step={step}
    />
  )
}

export default StepIndicator
