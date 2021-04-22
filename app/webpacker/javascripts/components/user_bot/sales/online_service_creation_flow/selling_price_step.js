"use strict";

import React, { useEffect } from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";
import SellingPriceEdit from "components/user_bot/sales/selling_price_edit";

const SellingPriceStep = ({step, next, prev}) => {
  const { dispatch, price, selected_online_service } = useGlobalContext()

  useEffect(() => {
    if (selected_online_service.charge_required) {
      dispatch({
        type: "SET_ATTRIBUTE",
        payload: {
          attribute: "price",
          value: { price_type: "one_time" }
        }
      })
    }
    else {
      dispatch({
        type: "SET_ATTRIBUTE",
        payload: {
          attribute: "price",
          value: { price_type: "free" }
        }
      })
      next()
    }
  }, [])

  return (
    <div className="form settings-flow centerize">
      <SalesFlowStepIndicator step={step} />
      <h3 className="header centerize line-break-content">{I18n.t("user_bot.dashboards.sales.online_service_creation.sell_what_price")}</h3>

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

      <div className="action-block">
        <button onClick={prev} className="btn btn-tarco">
          {I18n.t("action.prev_step")}
        </button>
        <button onClick={next} className="btn btn-yellow">
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default SellingPriceStep
