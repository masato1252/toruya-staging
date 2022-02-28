"use strict";

import React, { useEffect } from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";
import SellingNumberEdit from "components/user_bot/sales/selling_number_edit";

const SellingNumberStep = ({step, next, prev, lastStep}) => {
  const { dispatch, quantity, isQuantitySetup, isReadyForPreview, selected_online_service } = useGlobalContext()

  useEffect(() => {
    if (selected_online_service.recurring_charge_required) {
      next()
    }
  }, [])

  return (
    <div className="form settings-flow centerize">
      <SalesFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.sales.online_service_creation.sell_what_number")}</h3>

      <SellingNumberEdit
        quantity={quantity}
        handleQuantityChange={(quantity_value) => {
          dispatch({
            type: "SET_ATTRIBUTE",
            payload: {
              attribute: "quantity",
              value: quantity_value
            }
          })
        }}
      />

      <div className="action-block">
        <button onClick={prev} className="btn btn-tarco">
          {I18n.t("action.prev_step")}
        </button>
        <button onClick={() => {(isReadyForPreview()) ? lastStep(2) : next()}} className="btn btn-yellow"
            disabled={!isQuantitySetup()}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default SellingNumberStep
