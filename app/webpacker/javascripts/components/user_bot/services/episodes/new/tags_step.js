"use strict";

import React from "react";

import _ from "lodash";

import { useGlobalContext } from "./context/global_state";
import FlowStepIndicator from "./flow_step_indicator";

import EditTagsInput from "user_bot/services/episodes/shared/edit_tags_input";

const TagsStep  = ({next, step}) => {
  const { props, dispatch, new_tag, tags } = useGlobalContext()
  return (
    <div className="form settings-flow centerize">
      <FlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.settings.course.lessons.new.when_lesson_start")}</h3>
      <EditTagsInput
        new_tag={new_tag}
        tags={tags || []}
        existing_tags={props.online_service.tags}
        setNewTag={(value) => {
          dispatch({
            type: "SET_ATTRIBUTE",
            payload: {
              attribute: "new_tag",
              value: value
            }
          })
        }}
        setTags={(value) => {
          dispatch({
            type: "SET_ATTRIBUTE",
            payload: {
              attribute: "tags",
              value: value
            }
          })
        }}
      />

      <div className="action-block">
        <button onClick={next} className="btn btn-yellow">
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )
}

export default TagsStep
