"use strict";

import React from "react";
import ReactPlayer from 'react-player';

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";

const IntroductionSetupStep = ({step, next, prev, lastStep}) => {
  const { props, dispatch, introduction_video, isReadyForPreview } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <SalesFlowStepIndicator step={step} />
      <h3 className="header centerize break-line-content">{I18n.t("user_bot.dashboards.sales.online_service_creation.what_introduction_video")}</h3>
      <input
        placeholder={I18n.t("user_bot.dashboards.online_service_creation.what_is_video_url")}
        value={introduction_video?.url || ""}
        onChange={(event) =>
            dispatch({
              type: "SET_ATTRIBUTE",
              payload: {
                attribute: "introduction_video",
                value: {
                  url: event.target.value
                }
              }
            })
        }
        type="text"
        className="extend with-border"
      />
      <p className="margin-around text-align-left">
        {I18n.t("user_bot.dashboards.sales.online_service_creation.introduction_video_hint")}
      </p>

      <div className='video-player-wrapper'>
        <ReactPlayer
          className='react-player'
          light={false}
          url={introduction_video?.url}
          width='100%'
          height='100%'
        />
      </div>
      {introduction_video?.url && ReactPlayer.canPlay(introduction_video.url) && (
        <div className="action-block">
          <button onClick={prev} className="btn btn-tarco">
            {I18n.t("action.prev_step")}
          </button>
          <button onClick={() => {(isReadyForPreview()) ? lastStep(2) : next()}} className="btn btn-yellow">
            {I18n.t("action.next_step")}
          </button>
        </div>
      )}
    </div>
  )

}

export default IntroductionSetupStep
