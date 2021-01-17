"use strict";

import React from "react";
import ReactSelect from "react-select";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";

const UpsellStep = ({next, prev, step}) => {
  const { props, dispatch, upsell } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize">このサービス利用後に購入をお勧めしたい アップセル販売ページはありますか？</h3>
      <div>
        <label className="">
          <input name="upsell" type="radio" value="no"
            checked={upsell.type === "no"}
            onChange={() => {
              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "upsell",
                  value: {
                    type: "no",
                  }
                }
              })
            }}
          />
          アップセルはない
        </label>
      </div>

      <div>
        <label className="">
          <input name="upsell" type="radio" value="yes"
            checked={upsell.type === "yes"}
            onChange={() => {
              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "upsell",
                  value: {
                    type: "yes",
                  }
                }
              })
            }}
          />
          アップセルがある
          {upsell.type === "yes" && (
            <ReactSelect
              placeholder={'|セールスページを選択'}
              value={ _.isEmpty(upsell.service) ? "" : upsell.service}
              options={props.upsell_services}
              onChange={
                (service) => {
                  dispatch({
                    type: "SET_ATTRIBUTE",
                    payload: {
                      attribute: "upsell",
                      value: {
                        type: "yes",
                        service: service
                      }
                    }
                  })
                }
              }
            />
          )}
        </label>

        {
          !_.isEmpty(upsell.service) && (
            <>
              {upsell.service.type}
              {upsell.service.start_time}
              {upsell.service.end_time}
            </>
          )
        }
      </div>

      <div className="action-block">
        <button onClick={prev} className="btn btn-yellow" disabled={false}>
          {I18n.t("action.prev_step")}
        </button>
        <button onClick={next} className="btn btn-yellow" disabled={false}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default UpsellStep
