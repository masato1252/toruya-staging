"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";
import VideoContentSetup from "./contents/video_content_setup";

const SolutionStep = ({next, step}) => {
  const { props, dispatch, selected_goal, selected_solution } = useGlobalContext()
  const solutions = props.service_goals.find((goal) => goal.key === selected_goal).solutions

  if (selected_solution) {
    switch (selected_solution) {
      case "video":
        return (
          <VideoContentSetup
            next={next}
            step={step}
          />
        );
    }
  }

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.online_service_creation.what_is_your_solution")}</h3>
      {solutions.map((solution) => {
        return (
          <button
            onClick={() => {
              if (!solution.enabled) return;

              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "selected_solution",
                  value: solution.key
                }
              })
            }}
            className="btn btn-tarco btn-extend btn-flexible margin-around m10 relative"
            disabled={!solution.enabled}
            key={solution.key}>
            <h4>{solution.name}</h4>
            <p className="break-line-content text-align-left">
              {solution.description}
            </p>
            {!solution.enabled && <span className="preparing">{I18n.t('common.preparing')}</span>}
          </button>
        )
      })}
    </div>
  )

}

export default SolutionStep
