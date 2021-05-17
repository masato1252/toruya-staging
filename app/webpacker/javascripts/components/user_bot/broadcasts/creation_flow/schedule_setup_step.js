import React from "react";
import moment from "moment-timezone";

import I18n from 'i18n-js/index.js.erb';
import { useGlobalContext } from "./context/global_state";
import FlowStepIndicator from "./flow_step_indicator";
import { SubmitButton } from "shared/components";

const ScheduleSetupStep = ({next, step}) => {
  const { props, dispatch, schedule_at, createBroadcast } = useGlobalContext()
  moment.locale('ja');

  return (
    <div className="form settings-flow centerize">
      <FlowStepIndicator step={step} />
      <h3 className="header centerize">{"When you want to send"}</h3>
      <div className="text-left">
        <div className="margin-around m10 mt-0">
          <label>
            <input
              type="radio" name="schedule_at"
              checked={schedule_at == null}
              onChange={
                () => {
                  dispatch({
                    type: "SET_ATTRIBUTE",
                    payload: {
                      attribute: "schedule_at",
                      value: null
                    }
                  })
                }
              }
            />
            {I18n.t("common.send_now_label")}
          </label>
        </div>
        <div className="margin-around m10">
          <label>
            <input
              type="radio" name="send_later"
              checked={schedule_at !== null}
              onChange={
                () => {
                  dispatch({
                    type: "SET_ATTRIBUTE",
                    payload: {
                      attribute: "schedule_at",
                      value: moment().format("YYYY-MM-DDTHH:mm")
                    }
                  })
                }
              }
            />
            <input
              type="datetime-local"
              value={schedule_at || moment().format("YYYY-MM-DDTHH:mm")}
              onClick={() => {
                dispatch({
                  type: "SET_ATTRIBUTE",
                  payload: {
                    attribute: "schedule_at",
                    value: moment().format("YYYY-MM-DDTHH:mm")
                  }
                })
              }}
              onChange={(e) => {
                dispatch({
                  type: "SET_ATTRIBUTE",
                  payload: {
                    attribute: "schedule_at",
                    value: e.target.value
                  }
                })
              }}
            />
          </label>
        </div>
      </div>
      <div className="action-block">
        <SubmitButton
          handleSubmit={createBroadcast}
          btnWord={I18n.t("action.save")}
        />
      </div>
    </div>
  )
}

export default ScheduleSetupStep;
