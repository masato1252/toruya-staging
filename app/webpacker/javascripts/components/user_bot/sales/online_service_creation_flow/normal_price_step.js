"use strict";

import React, { useEffect } from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";
import NormalPriceEdit from "components/user_bot/sales/normal_price_edit";

const NormalPriceStep = ({step, next, prev, jump, lastStep}) => {
  const { dispatch, price, normal_price, isNormalPriceSetup, isReadyForPreview, selected_online_service } = useGlobalContext()

  useEffect(() => {
    // Most of times, when you have multiple payments solution, you don't need regular price
    if (price.price_types.length > 1) {
      next()
    }
  }, [])

  return (
    <div className="form settings-flow centerize">
      <SalesFlowStepIndicator step={step} />
      <h3 className="header centerize line-break-content">
        {I18n.t("user_bot.dashboards.sales.online_service_creation.what_normal_price")}
      </h3>

      <NormalPriceEdit
        normal_price={normal_price}
        handleNormalPriceChange={(normal_price_value) => {
          dispatch({
            type: "SET_ATTRIBUTE",
            payload: {
              attribute: "normal_price",
              value: normal_price_value
            }
          })
        }}
      />

      <div className="action-block">
        <button onClick={() => {
          if (selected_online_service.charge_required) {
            prev()
          }
          else {
            jump(0)
          }
        }} className="btn btn-tarco">
          {I18n.t("action.prev_step")}
        </button>
        <button onClick={() => {(isReadyForPreview()) ? lastStep(2) : next()}} className="btn btn-yellow"
            disabled={!isNormalPriceSetup()}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default NormalPriceStep
