"use strict";

import React, { useEffect } from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";
import SellingPriceEdit from "components/user_bot/sales/selling_price_edit";
import SellingRecurringPriceEdit from "components/user_bot/sales/selling_recurring_price_edit";

const SellingPriceStep = ({step, next, prev}) => {
  const { dispatch, price, selected_online_service } = useGlobalContext()

  useEffect(() => {
    let default_price_type;

    if (selected_online_service.recurring_charge_required) {
      default_price_type = "month"
    }
    else {
      default_price_type = selected_online_service.charge_required ? "one_time" : "free"
    }

      dispatch({
        type: "SET_ATTRIBUTE",
        payload: {
          attribute: "price",
          value: { price_types: [default_price_type] }
        }
      })

    if (default_price_type == "free") {
      next()
    }
  }, [])

  return (
    <div className="form settings-flow centerize">
      <SalesFlowStepIndicator step={step} />
      <h3 className="header centerize line-break-content">{I18n.t("user_bot.dashboards.sales.online_service_creation.sell_what_price")}</h3>

      {selected_online_service.one_time_charge_required && (
        <SellingPriceEdit
          price={price}
          handlePriceChange={(price_value) => {
            dispatch({
              type: "SET_ATTRIBUTE",
              payload: {
                attribute: "price",
                value: price_value
              }
            })
          }}
        />
      )}

      {selected_online_service.recurring_charge_required && (
        <SellingRecurringPriceEdit
          price={price}
          handlePriceChange={(price_value) => {
            dispatch({
              type: "SET_ATTRIBUTE",
              payload: {
                attribute: "price",
                value: price_value
              }
            })
          }}
        />
      )}

      <div className="action-block">
        <button onClick={prev} className="btn btn-tarco">
          {I18n.t("action.prev_step")}
        </button>
        <button onClick={next} className="btn btn-yellow" disabled={
          !price ||
            (!price.price_types.includes("one_time") && !price.price_types.includes("multiple_times") &&
            !price.price_types.includes("month") && !price.price_types.includes("year")) ||
            (price.price_types.includes("one_time") && !price.price_amounts?.one_time?.amount) ||
            (price.price_types.includes("multiple_times") && (!price.price_amounts?.multiple_times?.amount || !price.price_amounts?.multiple_times?.times)) ||
            (price.price_types.includes("month") && !price.price_amounts?.month?.amount) ||
            (price.price_types.includes("year") && !price.price_amounts?.year?.amount)
          }>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default SellingPriceStep
