"use strict";

import React, { useState } from "react";
import _ from "lodash";

import { useGlobalContext } from "context/user_bots/bookings/global_state";
import BookingPagePreview from "./booking_page_preview";
import { Translator } from "libraries/helper";
import BookingFlowStepIndicator from "./booking_flow_step_indicator";

const ConfirmationStep = ({next, jump, step}) => {
  const [submitting, setSubmitting] = useState(false)

  const {
    props, i18n, createBookingPage,
    selected_shop,
    selected_booking_option,
    selected_menu,
    new_booking_option_price,
    new_booking_option_tax_include,
    new_menu_name,
    new_menu_minutes,
    dispatch,
    ticket_quota
  } = useGlobalContext()

  const option = selected_booking_option.id ? selected_booking_option : {
    name: selected_menu?.label || new_menu_name,
    minutes: selected_menu?.minutes || new_menu_minutes,
    price_amount: new_booking_option_price,
    price: `${(parseInt(new_booking_option_price || 0)).toLocaleString()}${i18n.unit}(${new_booking_option_tax_include ? i18n.tax_include : i18n.tax_excluded})`
  }

  const booking_page = {
    title: Translator(i18n.default_label, {menu_name: option.name}),
    greeting: Translator(i18n.default_greeting, {menu_name: option.name})
  }

  return (
    <div className="booking-creation-flow form">
      <BookingFlowStepIndicator step={step} i18n={i18n} />
      {
        _.isEmpty(selected_booking_option) ? (
          <BookingPagePreview
            i18n={i18n}
            shop={selected_shop}
            booking_page={booking_page}
            booking_option={option}
            ticket_quota={ticket_quota}
            edit_option={() => {
              dispatch({type: "RESET_OPTION"})
              jump(1)
            }}
            edit_price={() => jump(2)}
          />
        ) : (
          <BookingPagePreview
            i18n={i18n}
            shop={selected_shop}
            booking_page={booking_page}
            booking_option={option}
            ticket_quota={ticket_quota}
            edit_option={() => jump(1)}
          />
        )
      }
      <div className="action-block">
        <button
          className="btn btn-yellow"
          disabled={submitting}
          onClick={async () => {
            if (submitting) return;
            setSubmitting(true)

            if (await createBookingPage()) {
              setSubmitting(false)
              next()
            } else  {
              setSubmitting(false)
            }
          }}>
            {submitting ? (
              <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
            ) : (
              i18n.use_these_settings_create_this_page
            )}
        </button>
      </div>
    </div>
  )
}

export default ConfirmationStep
