"use strict";

import React from "react";
import ReactSelect from "react-select";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";

const SellingNumberStep = ({step, next, prev, jump}) => {
  const { props, dispatch, quantity, isQuantitySetup, isReadyForPreview } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <SalesFlowStepIndicator step={step} />
      <h3 className="header centerize">販売個数を限定しますか？</h3>

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
            限定数を販売する(推奨)
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
              人まで
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
          ずっと販売する
        </label>
      </div>

      <div className="action-block">
        <button onClick={prev} className="btn btn-tarco">
          {I18n.t("action.prev_step")}
        </button>
        <button onClick={() => {(isReadyForPreview()) ? jump(11) : next()}} className="btn btn-yellow"
            disabled={!isQuantitySetup()}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default SellingNumberStep
