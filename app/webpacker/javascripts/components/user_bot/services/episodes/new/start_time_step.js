"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import FlowStepIndicator from "./flow_step_indicator";

const StartTimeStep  = ({next, step}) => {
  const { dispatch, start_time } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <FlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.settings.course.lessons.new.when_lesson_start")}</h3>
      <div className="centerize">
        <div className="margin-around">
          <label className="">
            <input name="start_type" type="radio" value="never"
              checked={start_time.start_type === "now"}
              onChange={() => {
                dispatch({
                  type: "SET_ATTRIBUTE",
                  payload: {
                    attribute: "start_time",
                    value: {
                      start_type: "now",
                    }
                  }
                })
              }}
            />
            {I18n.t("user_bot.dashboards.settings.course.lessons.new.right_after_service_start")}
          </label>
        </div>

        <div className="margin-around">
          <label className="">
            <div>
              <input name="start_type" type="radio" value="start_at"
                checked={start_time.start_type === "start_at"}
                onChange={() => {
                  dispatch({
                    type: "SET_ATTRIBUTE",
                    payload: {
                      attribute: "start_time",
                      value: {
                        start_type: "start_at",
                      }
                    }
                  })
                }}
              />
              {I18n.t("user_bot.dashboards.settings.course.lessons.new.start_on_specific_day")}
            </div>
            {start_time.start_type === "start_at" && (
              <input
                name="start_time_date_part"
                type="date"
                value={start_time.start_time_date_part || ""}
                onChange={(event) => {
                  dispatch({
                    type: "SET_ATTRIBUTE",
                    payload: {
                      attribute: "start_time",
                      value: {
                        start_type: "start_at",
                        start_time_date_part: event.target.value
                      }
                    }
                  })
                }}
              />
            )}
          </label>
        </div>

      </div>

      <div className="action-block">
        <button onClick={next} className="btn btn-yellow" disabled={
          !start_time.start_type ||
              (start_time.start_type === "start_at" && !start_time.start_time_date_part)
          }>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )
}

export default StartTimeStep
