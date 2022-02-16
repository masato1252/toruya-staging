"use strict";

import React, { useLayoutEffect } from "react";

import { useGlobalContext } from "./context/global_state";
import FlowStepIndicator from "./flow_step_indicator";
import { SubmitButton } from "shared/components";
import EpisodeContent from "user_bot/services/episodes/content";

const ConfirmationStep = ({next, jumpByKey, step}) => {
  const { createEpisode, name, selected_solution, content_url, note } = useGlobalContext()

  useLayoutEffect(() => {
    $("body").scrollTop(0)
  }, [])

  return (
    <div className="form settings-flow">
      <FlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.settings.course.lessons.new.below_is_what_you_want")}</h3>
      <div className="preview-hint">
        {I18n.t("user_bot.dashboards.online_service_creation.sale_page_like_this")}
      </div>
      <div className="online-service-page">
        <EpisodeContent
          episode={
            {
              name: name,
              note: note,
              solution_type: selected_solution,
              content_url: content_url
            }
          }
          demo={true}
          light={false}
          jumpByKey={jumpByKey}
        />
      </div>

      <div className="action-block margin-around">
        <SubmitButton
          handleSubmit={createEpisode}
          submitCallback={next}
          btnWord={I18n.t("user_bot.dashboards.settings.course.lessons.new.create_by_this_setting")}
        />
      </div>
    </div>
  )

}

export default ConfirmationStep
