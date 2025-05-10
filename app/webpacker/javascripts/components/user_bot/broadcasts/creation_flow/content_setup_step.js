import React, { useRef, useState, useEffect } from "react";

import I18n from 'i18n-js/index.js.erb';
import { useGlobalContext } from "./context/global_state";
import FlowStepIndicator from "./flow_step_indicator";
import { Translator } from "libraries/helper";

const ContentSetupStep = ({next, step, prev, jump}) => {
  const { props, dispatch, content } = useGlobalContext()
  const textareaRef = useRef();
  const [cursorPosition, setCursorPosition] = useState(0)

  useEffect(() => {
    textareaRef.current.focus()
  }, [content?.length])

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
    <div className="form settings-flow">
      <FlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.broadcast_creation.what_content_do_you_want")}</h3>
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
      <div className="preview-hint">{I18n.t("user_bot.dashboards.broadcast_creation.preview")}</div>
      <p className="margin-around p10 bg-gray rounded break-line-content">{content ? Translator(content, {...props.message}) : "" }</p>
      <div className="action-block centerize">
        <button onClick={() => {
          jump(0)
        }} className="btn btn-tarco">
          {I18n.t("action.prev_step")}
        </button>
        <button onClick={next} className="btn btn-yellow" disabled={!content}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )
}

export default ContentSetupStep;
