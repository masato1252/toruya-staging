"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import LessonFlowStepIndicator from "./lesson_flow_step_indicator";

const NameStep = ({next, prev, step}) => {
  const { props, dispatch, name } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <LessonFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.settings.course.lessons.new.what_is_lesson_name")}</h3>
      <input
        type="text"
        value={name || ""}
        className="extend with-border"
        onChange={(event) =>
            dispatch({
              type: "SET_ATTRIBUTE",
              payload: {
                attribute: "name",
                value: event.target.value
              }
            })
        }
      />

      <div className="action-block">
        <button onClick={next} className="btn btn-yellow" disabled={!name}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default NameStep
