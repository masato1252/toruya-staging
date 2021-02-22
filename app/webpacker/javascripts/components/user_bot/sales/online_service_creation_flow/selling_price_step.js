"use strict";

import React from "react";
import ReactSelect from "react-select";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";

const SellingPriceStep = ({step, next, prev, jump}) => {
  const { props, dispatch, price } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <SalesFlowStepIndicator step={step} />
      <h3 className="header centerize">この販売ページでは、幾らで販売しますか？</h3>

      <div className="margin-around">
        <label className="">
          <div>
            <input name="selling_type" type="radio" value="one_time" disabled={true} />
            １回払い(準備中)
          </div>
        </label>
      </div>

      <div className="margin-around">
        <label className="">
          <div>
            <input name="selling_type" type="radio" value="multiple_time" disabled={true} />
            分割払い(準備中)
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
            無料で提供
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
