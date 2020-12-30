"use strict";

import React from "react";
import FlowStepIndicator from "shared/flow_controller/flow_step_indicator";

const BookingFlowStepIndicator = ({step}) => {
  return (
    <FlowStepIndicator
      steps={[
        {icon: "fa-home", wording: I18n.t("user_bot.dashboards.sales.booking_page_creation.booking_step")},
        {icon: "fa-tags", wording: I18n.t("user_bot.dashboards.sales.booking_page_creation.content_step"), steps: [1, 2, 3, 4, 5, 6]},
        {icon: "fa-check", wording: I18n.t("user_bot.dashboards.sales.booking_page_creation.preview_step"), steps: [7]}
      ]}
      current_step={step}
    />
  )
}

export default BookingFlowStepIndicator
