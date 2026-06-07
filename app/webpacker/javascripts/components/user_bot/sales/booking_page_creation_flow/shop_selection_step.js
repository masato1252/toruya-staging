"use strict";

import React, { useEffect } from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";

const ShopSelectionStep = ({ next, step }) => {
  const { props, selected_shop, dispatch } = useGlobalContext()

  useEffect(() => {
    if (!props.multi_shop) {
      if (props.default_shop) {
        dispatch({
          type: "SET_ATTRIBUTE",
          payload: {
            attribute: "selected_shop",
            value: props.default_shop
          }
        })
      }
      next()
    }
  }, [])

  if (!props.multi_shop) {
    return null
  }

  return (
    <div className="form settings-flow">
      <SalesFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.booking_page_creation.book_which_shop")}</h3>
      <div className="margin-around">
        {props.shops_list.map((shop) => (
          <div key={`shop-${shop.id}-btn`} className="margin-around">
            <button
              onClick={() => {
                dispatch({
                  type: "SET_ATTRIBUTE",
                  payload: {
                    attribute: "selected_shop",
                    value: shop
                  }
                })
              }}
              className="btn btn-tarco btn-extend btn-tall"
            >
              {shop.name}
            </button>
          </div>
        ))}
      </div>
      {selected_shop?.id && (
        <div className="action-block">
          <button onClick={next} className="btn btn-yellow">
            {I18n.t("action.next_step")}
          </button>
        </div>
      )}
    </div>
  )
}

export default ShopSelectionStep
