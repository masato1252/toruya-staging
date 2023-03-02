"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";
import { SubmitButton, EndOnDaysRadio, EndAtRadio, NeverEndRadio } from "shared/components";

const EndtimeStep = ({next, prev, step, lastStep, step_key}) => {
  const { props, dispatch, end_time, createService, selected_goal } = useGlobalContext()

  const set_end_time_type = ({end_time_type}) => {
    dispatch({
      type: "SET_ATTRIBUTE",
      payload: {
        attribute: "end_time",
        value: {
          end_type: end_time_type
        }
      }
    })
  }

  const set_end_time_value = ({end_time_type, end_time_value_key, end_time_value}) => {
    dispatch({
      type: "SET_ATTRIBUTE",
      payload: {
        attribute: "end_time",
        value: {
          end_type: end_time_type,
          [end_time_value_key || end_time_type]: end_time_value
        }
      }
    })
  }

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} step_key={step_key} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.online_service_creation.what_is_end_time")}</h3>

      <EndOnDaysRadio
        end_time={end_time}
        set_end_time_type={() => {
          set_end_time_type({ end_time_type: 'end_on_days' })
        }}
        set_end_time_value={(end_time_value) => {
          set_end_time_value({ end_time_type: 'end_on_days', end_time_value })
        }}
      />

      <EndAtRadio
        end_time={end_time}
        set_end_time_type={() => {
          set_end_time_type({ end_time_type: 'end_at' })
        }}
        set_end_time_value={(end_time_value) => {
          set_end_time_value({ end_time_type: 'end_at', end_time_value_key: 'end_time_date_part', end_time_value })
        }}
      />

      <NeverEndRadio
        end_time={end_time}
        set_end_time_type={() => {
          set_end_time_type({ end_time_type: 'never' })
        }}
      />

      <div className="action-block">
        {selected_goal === 'course' || selected_goal === 'free_course' ? (
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
