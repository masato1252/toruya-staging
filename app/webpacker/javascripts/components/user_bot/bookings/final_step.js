"use strict";

import React from "react";

import { useGlobalContext } from "context/user_bots/bookings/global_state";
import BookingFlowStepIndicator from "./booking_flow_step_indicator";
import { UrlCopyBtn, BookingPageButtonCopyBtn } from "shared/components";

const FinalStep = ({step}) => {
  const { props, i18n, booking_page_id } = useGlobalContext()

  return (
    <div className="booking-creation-flow centerize">
      <BookingFlowStepIndicator step={step} i18n={i18n} />
      <h3 className="header centerize">{i18n.share_your_booking_page}</h3>
      <UrlCopyBtn url={Routes.booking_page_url(booking_page_id || 0)} />
      <BookingPageButtonCopyBtn booking_page_url={Routes.booking_page_url(booking_page_id || 0)} />
    </div>
  )
}

export default FinalStep;
