"use strict";

import React, { useEffect } from "react";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";
import { SubmitButton } from "shared/components";

const EndtimeStep = ({next, prev, step, lastStep}) => {
  const { props, dispatch, end_time, createService, selected_goal } = useGlobalContext()
  const selected_goal_option = props.service_goals.find((goal) => goal.key === selected_goal)

  useEffect(() => {
    if (selected_goal_option.skip_end_time_step_on_creation) next()
  }, [])

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.online_service_creation.what_is_end_time")}</h3>

      <div className="margin-around">
        <label className="">
          <div>
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
            {I18n.t("user_bot.dashboards.online_service_creation.expire_after_n_days")}
          </div>
          {end_time.end_type === "end_on_days" && (
            <>
            {I18n.t("user_bot.dashboards.online_service_creation.after_bought")}
            <input
              type="tel"
              value={end_time.end_on_days || ""}
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
            {I18n.t("user_bot.dashboards.online_service_creation.after_n_days")}
            </>
          )}
        </label>
      </div>

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
            {I18n.t("user_bot.dashboards.online_service_creation.expire_at")}
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
          {I18n.t("user_bot.dashboards.online_service_creation.never_expire")}
        </label>
      </div>

      <div className="action-block">
        {selected_goal === 'course' ? (
          <SubmitButton
            disabled={
              !end_time.end_type ||
                (end_time.end_type === "end_on_days" && !end_time.end_on_days) ||
                (end_time.end_type === "end_at" && !end_time.end_time_date_part)
            }
            handleSubmit={createService}
            submitCallback={lastStep}
            btnWord={I18n.t("user_bot.dashboards.online_service_creation.create_by_this_setting")}
          />
        ) : (
          <button onClick={next} className="btn btn-yellow" disabled={
            !end_time.end_type ||
              (end_time.end_type === "end_on_days" && !end_time.end_on_days) ||
                (end_time.end_type === "end_at" && !end_time.end_time_date_part)
            }>
            {I18n.t("action.next_step")}
          </button>
        )}
      </div>
    </div>
  )

}

export default EndtimeStep
