"use strict";

import React from "react";
import FlowStepIndicator from "shared/flow_controller/flow_step_indicator";
import I18n from 'i18n-js/index.js.erb';

const LessonFlowStepIndicator = ({step}) => {
  return (
    <FlowStepIndicator
      steps={[
        {icon: "fa-file-alt", wording: I18n.t("user_bot.dashboards.service_creation.content_step"), steps: [0, 1, 2]},
        {icon: "fa-hourglass-half", wording: I18n.t("user_bot.dashboards.settings.course.lessons.new.start_time_step"), steps: [3]},
        {icon: "fa-check", wording: I18n.t("user_bot.dashboards.service_creation.check_step"), steps: [4]}
      ]}
      current_step={step}
    />
  )
}

export default LessonFlowStepIndicator
