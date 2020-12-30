"use strict";

import React from "react";
import ReactSelect from "react-select";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";

const BookingPageSelectionStep = ({next, step}) => {
  const { props, selected_booking_page, dispatch } = useGlobalContext()

  return (
    <div className="form settings-flow">
      <SalesFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.sales.booking_page_creation.sell_what_page")}</h3>
      <ReactSelect
        Value={selected_booking_page || ""}
        defaultValue={selected_booking_page || ""}
        placeholder={I18n.t("user_bot.dashboards.sales.booking_page_creation.select_booking_page")}
        options={props.booking_pages}
        onChange={
          (booking_page_option)=> {
            dispatch({
              type: "SET_ATTRIBUTE",
              payload: {
                attribute: "selected_booking_page",
                value: booking_page_option.value
              }
            })
          }
        }
      />
      {selected_booking_page && (
        <div className="item-container">
          <div className="item-element">
            <span>{I18n.t("user_bot.dashboards.booking_page_creation.booking_price")}</span>
            <span>{selected_booking_page?.price}</span>
          </div>
          <div className="item-element">
            <span>{I18n.t("settings.booking_page.form.sale_start")}</span>
            <span>{selected_booking_page?.start_time}</span>
          </div>
          <div className="item-element">
            <span>{I18n.t("settings.booking_page.form.sale_end")}</span>
            <span>{selected_booking_page?.end_time}</span>
          </div>
        </div>
      )}

      <div className="action-block">
        <button onClick={next} className="btn btn-yellow" disabled={!selected_booking_page}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default BookingPageSelectionStep
