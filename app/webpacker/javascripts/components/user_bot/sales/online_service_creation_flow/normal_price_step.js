"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";

const NormalPriceStep = ({step, next, prev, lastStep}) => {
  const { dispatch, normal_price, isNormalPriceSetup, isReadyForPreview } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <SalesFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.sales.online_service_creation.what_normal_price")}</h3>

      <div className="margin-around">
        <label className="">
          <div>
            <input
              name="selling_type" type="radio" value="cost"
              checked={normal_price.price_type === "cost"}
              onChange={() => {
                dispatch({
                  type: "SET_ATTRIBUTE",
                  payload: {
                    attribute: "normal_price",
                    value: {
                      price_type: "cost"
                    }
                  }
                })
              }}
            />
            {I18n.t("user_bot.dashboards.sales.online_service_creation.normal_price_cost")}
            <br />
            {normal_price.price_type === "cost" && (
              <>
                <input
                  type="tel"
                  value={normal_price.price_amount || ""}
                  onChange={(event) => {
                    dispatch({
                      type: "SET_ATTRIBUTE",
                      payload: {
                        attribute: "normal_price",
                        value: {
                          price_type: "cost",
                          price_amount: event.target.value
                        }
                      }
                    })
                  }} />
                  {I18n.t("common.unit")}
                </>
            )}
          </div>
        </label>
      </div>

      <div className="margin-around">
        <label className="">
          <div>
            <input
              name="selling_type"
              type="radio"
              value="free"
              checked={normal_price.price_type === "free"}
              onChange={() => {
                dispatch({
                  type: "SET_ATTRIBUTE",
                  payload: {
                    attribute: "normal_price",
                    value: {
                      price_type: "free"
                    }
                  }
                })
              }}
            />
            {I18n.t("user_bot.dashboards.sales.online_service_creation.normal_price_free")}
          </div>
        </label>
      </div>

      <div className="action-block">
        <button onClick={prev} className="btn btn-tarco">
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
