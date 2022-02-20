"use strict"

import React from "react";
import ReactPlayer from 'react-player';
import UrlInput from "shared/edit/url_input";

const VideoUrl = ({register, errors, watch, name, placeholder}) => (
  <>
    <UrlInput register={register} errors={errors} name={name} placeholder={placeholder} />
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
