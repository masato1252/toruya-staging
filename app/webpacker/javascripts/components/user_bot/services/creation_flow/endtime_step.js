"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";

const EndtimeStep = ({next, prev, step}) => {
  const { props, dispatch, end_time } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize">このサービスは、利用期限がありますか？</h3>

      <div>
        <label className="">
          <input
            name="end_type" type="radio" value="end_on_days"
            checked={end_time.end_type === "end_on_days"}
            onChange={() => {
              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "end_time",
                  value: {
                    end_type: "end_on_days"
                  }
                }
              })
            }}
          />
          購入後X日後まで
          {end_time.end_type === "end_on_days" && (
            <input
              type="tel"
              onChange={(event) => {
                dispatch({
                  type: "SET_ATTRIBUTE",
                  payload: {
                    attribute: "end_time",
                    value: {
                      end_type: "end_on_days",
                      end_on_days: event.target.value
                    }
                  }
                })
            }} />
          )}
        </label>
      </div>

      <div>
        <label className="">
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
          決まった日時まで
          {end_time.end_type === "end_at" && (
            <input
              name="end_time_date_part"
              type="date"
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

      <div>
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
          ずっと利用可能
        </label>
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

export default EndtimeStep
