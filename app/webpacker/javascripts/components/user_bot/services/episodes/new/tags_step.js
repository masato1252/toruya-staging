"use strict";

import React from "react";

import _ from "lodash";

import { useGlobalContext } from "./context/global_state";
import FlowStepIndicator from "./flow_step_indicator";

const TagsStep  = ({next, step}) => {
  const { props, dispatch, new_tag, tags } = useGlobalContext()
  return (
    <div className="form settings-flow centerize">
      <FlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.settings.course.lessons.new.when_lesson_start")}</h3>
      <input
        type="text"
        value={new_tag || ""}
        className="extend with-border"
        onChange={(event) =>
            dispatch({
              type: "SET_ATTRIBUTE",
              payload: {
                attribute: "new_tag",
                value: event.target.value
              }
            })
        }
      />
      <button
        disabled={!new_tag}
        onClick={() => {
          if (!new_tag) return;

          dispatch({
            type: "SET_ATTRIBUTE",
            payload: {
              attribute: "tags",
              value: _.uniq([...tags, new_tag])
            }
          })

          dispatch({
            type: "SET_ATTRIBUTE",
            payload: {
              attribute: "new_tag",
              value: null
            }
          })
        }}
        className="btn btn-orange mar">
        {I18n.t("action.add_more")}
      </button>
      <div className="margin-around">
        {tags.map(tag => (
          <button
            className="btn btn-gray mx-2 my-2"
            onClick={() => {
              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "tags",
                  value: tags.filter(item => item !== tag)
                }
              })
            }}>
            {tag}
          </button>
        ))}
      </div>

      <div className="margin-around">
        {props.online_service.tags.map(tag => (
          <button
            className="btn btn-gray mx-2 my-2"
            onClick={() => {
              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "tags",
                  value: _.uniq([...tags, tag])
                }
              })
            }}>
            {tag}
          </button>
        ))}
      </div>

      <div className="action-block">
        <button onClick={next} className="btn btn-yellow">
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )
}

export default TagsStep
