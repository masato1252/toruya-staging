"use strict";

import React, { useEffect } from "react";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";
import EditMessageTemplate from "user_bot/services/edit_message_template";

const LineMessageStep = ({next, step}) => {
  const { props, dispatch, name, selected_goal, message_template, isMessageSetup } = useGlobalContext()
  const selected_goal_option = props.service_goals.find((goal) => goal.key === selected_goal)

  useEffect(() => {
    if (selected_goal_option.skip_line_message_step_on_creation) next()
  }, [])

  const onDrop = (picture, pictureDataUrl)=> {
    dispatch({
      type: "SET_NESTED_ATTRIBUTE",
      payload: {
        parent_attribute: "message_template",
        attribute: "picture",
        value: picture[0]
      }
    })

    dispatch({
      type: "SET_NESTED_ATTRIBUTE",
      payload: {
        parent_attribute: "message_template",
        attribute: "picture_url",
        value: pictureDataUrl
      }
    })
  }

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.online_service_creation.setup_line_bot_for_customers")}</h3>
      <EditMessageTemplate
        service_name={name}
        message_template={message_template}
        handleMessageTemplateChange={(attr, value) => {
          dispatch({
            type: "SET_NESTED_ATTRIBUTE",
            payload: {
              parent_attribute: "message_template",
              attribute: attr,
              value: value
            }
          })
        }}
        handlePictureChange={onDrop}
      />

      <div className="action-block">
        <button onClick={next} className="btn btn-yellow" disabled={!isMessageSetup()}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default LineMessageStep
