"use strict";

import React from "react";
import ReactPlayer from 'react-player';

import { useGlobalContext } from "../context/global_state";
import ServiceFlowStepIndicator from "../services_flow_step_indicator";

const VideoContentSetup = ({next, step}) => {
  const { props, dispatch, content } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize">どの動画をサービス提供しますか？</h3>
      <input
        onChange={(event) =>
            dispatch({
              type: "SET_ATTRIBUTE",
              payload: {
                attribute: "content",
                value: {
                  url: event.target.value
                }
              }
            })
        }
        type="text"
        className="extend with-border"
      />
      <div className='video-player-wrapper'>
        <ReactPlayer
          className='react-player'
          light={true}
          url={content?.url}
          width='100%'
          height='100%'
        />
      </div>

      <div className="action-block">
        <button onClick={next} className="btn btn-yellow" disabled={false}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default VideoContentSetup
