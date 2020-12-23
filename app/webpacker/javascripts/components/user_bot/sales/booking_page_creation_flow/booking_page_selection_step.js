"use strict";

import React from "react";
import ReactSelect from "react-select";
import { Controller } from "react-hook-form";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";

const BookingPageSelectionStep = ({next, step}) => {
  const { props, selected_booking_page, dispatch } = useGlobalContext()

  return (
    <div className="form">
      <SalesFlowStepIndicator step={step} />
      <ReactSelect
        Value={selected_booking_page || ""}
        defaultValue={selected_booking_page || ""}
        placeholder="Select a page"
        options={props.booking_pages}
        onChange={
          (booking_page)=> {
            dispatch({
              type: "SET_ATTRIBUTE",
              payload: {
                attribute: "selected_booking_page",
                value: booking_page.value
              }
            })
          }
        }
      />
      {selected_booking_page?.name}

      <div className="action-block">
        <button onClick={next} className="btn btn-yellow">
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default BookingPageSelectionStep
