"use strict";

import React from "react";
import ReactPlayer from 'react-player';
import I18n from 'i18n-js/index.js.erb';

const OnlineServiceSolution = ({solution_type, content, ...rest}) => {
  if (!content?.url) return <></>

  switch (solution_type) {
    case "video":
      return (
        <div className='video-player-wrapper'>
          <ReactPlayer
            className='react-player'
            url={content.url}
            width='100%'
            height='100%'
            controls={true}
            {...rest}
          />
        </div>
      );
    case "pdf":
      return (
        <a href={content.url}>PDF Link</a>
      );
    default:
      return <></>
  }
}

export default OnlineServiceSolution
