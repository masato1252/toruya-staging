"use strict";

import React from "react";
import ReactPlayer from 'react-player';
import I18n from 'i18n-js/index.js.erb';

const OnlineServiceSolution = ({solution, content, ...rest}) => {
  switch (solution) {
    case "video":
      return (
        <div className='video-player-wrapper'>
          <ReactPlayer
            className='react-player'
            url={content.url}
            width='100%'
            height='100%'
            {...rest}
          />
        </div>
      );
    default:
      return <></>
  }
}

export default OnlineServiceSolution
