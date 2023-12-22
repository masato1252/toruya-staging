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
      <div className="action-block">
        <h4 className="margin-around break-line-content">{I18n.t("user_bot.dashboards.booking_page_creation.create_a_sale_page")}</h4>

        <a href={Routes.new_lines_user_bot_sales_booking_page_url(props.business_owner_id, {booking_page_id: booking_page_id})} className="btn btn-yellow btn-flexible">
          <i className="fa fa-cart-arrow-down fa-4x"></i>
          <h4>{I18n.t("user_bot.dashboards.booking_page_creation.create_a_sale_page_btn")}</h4>
        </a>
      </div>
    </div>
  )
}

export default FinalStep;
