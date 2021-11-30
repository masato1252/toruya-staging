"use strict"

import React from "react";
import ReactPlayer from 'react-player';

const VideoUrl = ({register, watch, name, placeholder}) => (
  <>
    <div className="field-row">
      <input autoFocus={true} ref={register({ required: true })} name={name} placeholder={placeholder} className="extend" type="text" />
    </div>
    <div className='video-player-wrapper'>
      <ReactPlayer
        className='react-player'
        light={false}
        url={watch("content_url") || ""}
        width='100%'
        height='100%'
      />
    </div>
  </>
)

export default VideoUrl
