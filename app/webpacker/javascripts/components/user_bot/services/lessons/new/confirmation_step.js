"use strict";

import React, { useLayoutEffect } from "react";

import { useGlobalContext } from "./context/global_state";
import LessonFlowStepIndicator from "./lesson_flow_step_indicator";
import { SubmitButton } from "shared/components";
import LessonContent from "user_bot/services/course/lesson_content";

const ConfirmationStep = ({next, prev, jump, step}) => {
  const { props, dispatch, createLesson, name, selected_solution, content_url, note } = useGlobalContext()

  useLayoutEffect(() => {
    $("body").scrollTop(0)
  }, [])

  return (
    <div className="form settings-flow">
      <LessonFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.online_service_creation.below_is_what_you_want")}</h3>
      <div className="preview-hint">
        {I18n.t("user_bot.dashboards.online_service_creation.sale_page_like_this")}
      </div>
      <div className="online-service-page">
        <LessonContent
          lesson={
            {
              name: name,
              note: note,
              solution_type: selected_solution,
              content_url: content_url
            }
          }
          demo={true}
          light={false}
          jump={jump}
        />
      </div>

      <div className="action-block margin-around">
        <SubmitButton
          handleSubmit={createLesson}
          submitCallback={next}
          btnWord={I18n.t("user_bot.dashboards.online_service_creation.create_by_this_setting")}
        />
      </div>
    </div>
  )

}

export default ConfirmationStep
