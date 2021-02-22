"use strict";

import React from "react";
import ReactSelect from "react-select";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";

const NormalPriceStep = ({step, next, prev, jump}) => {
  const { props, dispatch, normal_price, isNormalPriceSetup, isReadyForPreview } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <SalesFlowStepIndicator step={step} />
      <h3 className="header centerize">先ほど入力した価格とは別に 通常価格がありますか？</h3>

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
            はい、あります
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
            いいえ、ありません
          </div>
        </label>
      </div>

      <div className="action-block">
        <button onClick={prev} className="btn btn-tarco">
          {I18n.t("action.prev_step")}
        </button>
        <button onClick={() => {(isReadyForPreview()) ? jump(11) : next()}} className="btn btn-yellow"
            disabled={!isNormalPriceSetup()}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default NormalPriceStep
