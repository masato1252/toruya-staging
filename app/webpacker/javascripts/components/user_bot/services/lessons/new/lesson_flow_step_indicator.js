"use strict";

import React from "react";
import FlowStepIndicator from "shared/flow_controller/flow_step_indicator";

const LessonFlowStepIndicator = ({step}) => {
  return (
    <FlowStepIndicator
      steps={[
        {icon: "fa-flag", wording: I18n.t("user_bot.dashboards.service_creation.goal_step")},
        {icon: "fa-file-alt", wording: I18n.t("user_bot.dashboards.service_creation.content_step"), steps: [1, 2, 3]},
        {icon: "fa-hourglass-half", wording: I18n.t("user_bot.dashboards.service_creation.time_step"), steps: [4]},
        {icon: "fa-cart-plus", wording: I18n.t("user_bot.dashboards.service_creation.upsell_step"), steps: [5]},
        {icon: "fa-check", wording: I18n.t("user_bot.dashboards.service_creation.check_step"), steps: [6]}
      ]}
      current_step={step}
    />
  )
}

export default LessonFlowStepIndicator
