"use strict";

import React from "react";

import { useGlobalContext } from "context/user_bots/bookings/global_state";
import BookingFlowStepIndicator from "./booking_flow_step_indicator";

const NoteSetupStep = ({next, step}) => {
  const { props, i18n, dispatch, note } = useGlobalContext()

  return (
    <div className="booking-creation-flow centerize">
      <BookingFlowStepIndicator step={step} i18n={i18n} />
      <h3 className="header centerize">{i18n.note_for_this_option}</h3>
      <textarea
        placeholder={i18n.enter_note_policy}
        value={note}
        onChange={
          (event) => {
            dispatch({
              type: "SET_ATTRIBUTE",
              payload: {
                attribute: "note",
                value: event.target.value
              }
            })
          }
        } />

      <div className="action-block">
        <button
          className="btn btn-yellow"
          onClick={next}>
          {i18n.use_this_page_note}
        </button>
      </div>
    </div>
  )
}

export default NoteSetupStep
