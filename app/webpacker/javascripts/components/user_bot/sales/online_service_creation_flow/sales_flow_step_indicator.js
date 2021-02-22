"use strict";

import React from "react";
import FlowStepIndicator from "shared/flow_controller/flow_step_indicator";

const BookingFlowStepIndicator = ({step}) => {
  return (
    <FlowStepIndicator
      steps={[
        {icon: "fa-shopping-cart", wording: I18n.t("user_bot.dashboards.sales.online_service_creation.service_step")},
        {icon: "fa-money-bill-wave", wording: I18n.t("user_bot.dashboards.sales.online_service_creation.price_step"), steps: [1, 2]},
        {icon: "fa-hourglass-half", wording: I18n.t("user_bot.dashboards.sales.online_service_creation.limitation_step"), steps: [3, 4]},
        {icon: "fa-file-alt", wording: I18n.t("user_bot.dashboards.sales.online_service_creation.content_step"), steps: [5, 6, 7, 8, 9, 10]},
        {icon: "fa-check", wording: I18n.t("user_bot.dashboards.sales.online_service_creation.preview_step"), steps: [11]}
      ]}
      current_step={step}
    />
  )
}

export default BookingFlowStepIndicator
