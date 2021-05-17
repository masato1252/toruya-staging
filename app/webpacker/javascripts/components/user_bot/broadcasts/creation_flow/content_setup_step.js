import React, { useRef, useState, useEffect } from "react";

import I18n from 'i18n-js/index.js.erb';
import { useGlobalContext } from "./context/global_state";
import FlowStepIndicator from "./flow_step_indicator";
import { Translator } from "libraries/helper";

const ContentSetupStep = ({next, step}) => {
  const { props, dispatch, content } = useGlobalContext()
  const textareaRef = useRef();
  const [cursorPosition, setCursorPosition] = useState(0)

  useEffect(() => {
    textareaRef.current.focus()
  }, [content.length])

  const insertKeyword = (keyword) => {
    const newContent = content.substring(0, cursorPosition) + keyword + content.substring(cursorPosition)

    dispatch({
      type: "SET_ATTRIBUTE",
      payload: {
        attribute: "content",
        value: newContent
      }
    })
  }

  return (
    <div className="form settings-flow centerize">
      <FlowStepIndicator step={step} />
      <h3 className="header centerize">{"Write the content"}</h3>
      <textarea
        ref={textareaRef}
        autoFocus={true}
        className="extend with-border"
        value={content}
        onChange={(event) => {
          dispatch({
            type: "SET_ATTRIBUTE",
            payload: {
              attribute: "content",
              value: event.target.value
            }
          })
        }}
        onBlur={() => {
          setCursorPosition(textareaRef.current.selectionStart)
        }}
        onClick={() => {
          setCursorPosition(textareaRef.current.selectionStart)
        }}
      />
      <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{customer_name}") }}> {I18n.t("user_bot.dashboards.settings.custom_message.buttons.customer_name")} </button>
      <p className="p-6 bg-gray rounded break-line-content">
        {Translator(content, {...props.message})}
      </p>
      <div className="action-block">
        <button onClick={next} className="btn btn-yellow" disabled={!content}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )
}

export default ContentSetupStep;
