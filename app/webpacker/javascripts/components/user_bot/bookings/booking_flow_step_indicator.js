"use strict";

import React from "react";
import FlowStepIndicator from "shared/flow_controller/flow_step_indicator";

const BookingFlowStepIndicator = ({step, i18n}) => {
  return (
    <FlowStepIndicator
      steps={[
        {icon: "fa-home", wording: i18n.booking_shop},
        {icon: "fa-tags", wording: i18n.booking_options},
        {icon: "fa-money-bill-wave", wording: i18n.booking_price},
        {icon: "fa-exclamation-triangle", wording: i18n.booking_note},
        {icon: "fa-check", wording: i18n.check_this_page}
      ]}
      current_step={step}
    />
  )
}

export default BookingFlowStepIndicator
