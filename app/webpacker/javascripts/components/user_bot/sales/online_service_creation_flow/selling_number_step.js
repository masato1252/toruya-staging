"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";

const SellingNumberStep = ({step, next, prev, lastStep}) => {
  const { dispatch, quantity, isQuantitySetup, isReadyForPreview } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <SalesFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.sales.online_service_creation.sell_what_number")}</h3>

      <div className="margin-around">
        <label className="">
          <div>
            <input name="quantity_type" type="radio" value="limited"
              checked={quantity.quantity_type === "limited"}
              onChange={() => {
                dispatch({
                  type: "SET_ATTRIBUTE",
                  payload: {
                    attribute: "quantity",
                    value: {
                      quantity_type: "limited"
                    }
                  }
                })
              }}
            />
            {I18n.t("user_bot.dashboards.sales.online_service_creation.sell_limit_number")}
          </div>
          {quantity.quantity_type === "limited" && (
            <>
                <input
                name="quantity"
                type="tel"
                value={quantity.quantity_value || ""}
                onChange={(event) => {
                  dispatch({
                    type: "SET_ATTRIBUTE",
                    payload: {
                      attribute: "quantity",
                      value: {
                        quantity_type: "limited",
                        quantity_value: event.target.value
                      }
                    }
                  })
                }}
              />
              {I18n.t("user_bot.dashboards.sales.online_service_creation.until_people_number")}
            </>
          )}
        </label>
      </div>

      <div className="margin-around">
        <label className="">
          <input name="quantity_type" type="radio" value="never"
            checked={quantity.quantity_type === "unlimited"}
            onChange={() => {
              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "quantity",
                  value: {
                    quantity_type: "unlimited",
                  }
                }
              })
            }}
          />
          {I18n.t("user_bot.dashboards.sales.online_service_creation.sell_unlimit_number")}
        </label>
      </div>

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
