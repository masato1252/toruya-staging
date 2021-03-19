"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";

const SellingTimeStep = ({step, next, prev, lastStep}) => {
  const { dispatch, end_time, isEndTimeSetup, isReadyForPreview } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <SalesFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.sales.online_service_creation.what_selling_end_at")}</h3>

      <div className="margin-around">
        <label className="">
          <div>
            <input name="end_type" type="radio" value="end_at"
              checked={end_time.end_type === "end_at"}
              onChange={() => {
                dispatch({
                  type: "SET_ATTRIBUTE",
                  payload: {
                    attribute: "end_time",
                    value: {
                      end_type: "end_at"
                    }
                  }
                })
              }}
            />
            {I18n.t("user_bot.dashboards.sales.online_service_creation.selling_end_on")}
          </div>
          {end_time.end_type === "end_at" && (
            <input
              name="end_time_date_part"
              type="date"
              value={end_time.end_time_date_part || ""}
              onChange={(event) => {
                dispatch({
                  type: "SET_ATTRIBUTE",
                  payload: {
                    attribute: "end_time",
                    value: {
                      end_type: "end_at",
                      end_time_date_part: event.target.value
                    }
                  }
                })
              }}
            />
          )}
        </label>
      </div>

      <div className="margin-around">
        <label className="">
          <input name="end_type" type="radio" value="never"
            checked={end_time.end_type === "never"}
            onChange={() => {
              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "end_time",
                  value: {
                    end_type: "never",
                  }
                }
              })
            }}
          />
          {I18n.t("user_bot.dashboards.sales.online_service_creation.selling_forever")}
        </label>
      </div>

      <div className="action-block">
        <button onClick={prev} className="btn btn-tarco">
          {I18n.t("action.prev_step")}
        </button>
        <button onClick={() => {(isReadyForPreview()) ? lastStep(2) : next()}} className="btn btn-yellow"
            disabled={!isEndTimeSetup()}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default SellingTimeStep
