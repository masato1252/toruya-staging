"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";
import VideoContentSetup from "./contents/video_content_setup";

const SolutionStep = ({next, prev, step}) => {
  const { props, dispatch, selected_goal, selected_solution } = useGlobalContext()
  const solutions = props.service_goals.find((goal) => goal.key === selected_goal).solutions.filter(solution => solution.enabled)

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
      <h3 className="header centerize">このサービスで提供する内容は何ですか？</h3>
      {solutions.map((solution) => {
        return (
          <button
            onClick={() => {
              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "selected_solution",
                  value: solution.key
                }
              })
            }}
            className="btn btn-tarco btn-extend btn-flexible margin-around"
            key={solution.key}>
            <h4>{solution.name}</h4>
            <p className="break-line-content">
              {solution.description}
            </p>
          </button>
        )
      })}

      <div className="action-block">
        <button onClick={prev} className="btn btn-yellow" disabled={false}>
          {I18n.t("action.prev_step")}
        </button>
        <button onClick={next} className="btn btn-yellow" disabled={false}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default SolutionStep
