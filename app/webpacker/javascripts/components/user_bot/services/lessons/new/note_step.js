"use strict";

import React from "react";
import TextareaAutosize from 'react-autosize-textarea';

import { useGlobalContext } from "./context/global_state";
import LessonFlowStepIndicator from "./lesson_flow_step_indicator";

const NoteStep = ({next, prev, step}) => {
  const { props, dispatch, note } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <LessonFlowStepIndicator step={step} />
      <h3 className="header centerize">{'Note'}</h3>
      <TextareaAutosize
        className="what-user-get-tip extend with-border"
        value={note || ""}
        onChange={(event) =>
          dispatch({
            type: "SET_ATTRIBUTE",
            payload: {
              attribute: "note",
              value: event.target.value
            }
          })
        }
      />

      <div className="action-block">
        <button onClick={next} className="btn btn-yellow" disabled={!note}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )
}

export default NoteStep
