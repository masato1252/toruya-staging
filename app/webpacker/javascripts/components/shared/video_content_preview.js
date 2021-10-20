
"use strict"

import React, { useState } from "react";
import ReactPlayer from 'react-player';

const VideoContentPreview = ({url, handleUrlChange}) => {
  return (
    <>
      <input
        placeholder={I18n.t("user_bot.dashboards.online_service_creation.what_is_video_url")}
        value={url || ""}
        onChange={handleUrlChange}
        type="text"
        className="extend with-border"
      />
      <p className="margin-around text-align-left">
        {I18n.t("user_bot.dashboards.online_service_creation.video_hint")}
      </p>

      <div className='video-player-wrapper'>
        <ReactPlayer
          className='react-player'
          light={false}
          url={url}
          width='100%'
          height='100%'
        />
      </div>
    </>
  )
}
export default VideoContentPreview;
