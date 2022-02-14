"use strict";

import React, { useEffect } from "react";

import ImageUploader from "react-images-upload";
import TextareaAutosize from 'react-autosize-textarea';

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";

const LineMessageStep = ({next, prev, step}) => {
  const { props, dispatch, name, selected_goal, message_template } = useGlobalContext()
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
      <h3 className="header centerize">{'Line Message'}</h3>
      <div className="product-content-deails">
        <ImageUploader
          defaultImages={message_template.picture_url.length ? [message_template.picture_url] : []}
          withIcon={false}
          withPreview={true}
          withLabel={false}
          buttonText={I18n.t("user_bot.dashboards.sales.booking_page_creation.content_picture_requirement_tip")}
          singleImage={true}
          onChange={onDrop}
          imgExtension={[".jpg", ".png", ".jpeg", ".gif"]}
          maxFileSize={5242880}
        />
        <h3 className="text-left">{name}</h3>
        <TextareaAutosize
          className="extend with-border"
          value={message_template.content}
          placeholder={I18n.t("user_bot.dashboards.sales.booking_page_creation.what_buyer_future")}
          onChange={(event) => {
            dispatch({
              type: "SET_NESTED_ATTRIBUTE",
              payload: {
                parent_attribute: "message_template",
                attribute: "content",
                value: event.target.value
              }
            })
          }}
        />
        <button className="btn btn-gray btn-tall w-full my-2" disabled ></button>
      </div>

      <div className="action-block">
        <button onClick={next} className="btn btn-yellow" disabled={false}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default LineMessageStep
