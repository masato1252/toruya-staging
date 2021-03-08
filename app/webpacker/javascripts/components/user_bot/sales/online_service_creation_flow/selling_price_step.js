"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";

const SellingPriceStep = ({step, next, prev}) => {
  const { price } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <SalesFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.sales.online_service_creation.sell_what_price")}</h3>

      <div className="margin-around">
        <label className="">
          <div>
            <input name="selling_type" type="radio" value="one_time" disabled={true} />
            <span className="line-through">１回払い</span>(準備中)
          </div>
        </label>
      </div>

      <div className="margin-around">
        <label className="">
          <div>
            <input name="selling_type" type="radio" value="multiple_time" disabled={true} />
            <span className="line-through">分割払い</span>(準備中)
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
              defaultChecked={price.price_type === "free"}
            />
            {I18n.t("user_bot.dashboards.sales.online_service_creation.sell_free_price")}
          </div>
        </label>
      </div>

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
