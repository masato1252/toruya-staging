"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';
import FlowStepIndicator from "shared/flow_controller/flow_step_indicator";

const StepIndicator = ({step}) => {
  return (
    <FlowStepIndicator
      steps={[
        {icon: "fa-users", wording: I18n.t("user_bot.dashboards.broadcast_creation.filters_step"), steps: [0, 1]},
        {icon: "fa-comment", wording: I18n.t("user_bot.dashboards.broadcast_creation.content_step"), steps: [2]},
        {icon: "fa-calendar-alt", wording: I18n.t("user_bot.dashboards.broadcast_creation.schedule_step"), steps: [3]}
      ]}
      current_step={step}
    />
  )
}

export default StepIndicator
