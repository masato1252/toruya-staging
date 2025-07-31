"use strict";

import React from "react";
import ReactPlayer from 'react-player';
import I18n from 'i18n-js/index.js.erb';

const OnlineServiceSolution = ({solution_type, content_url, ...rest}) => {
  if (!content_url) return <></>

  switch (solution_type) {
    case "video":
      return (
        <>
          <div className='video-player-wrapper extend'>
            <ReactPlayer
              className='react-player'
              url={content_url}
              width='100%'
              height='100%'
              controls={true}
              {...rest}
            />
          </div>
          <a href={content_url} target="_blank">
            {content_url}
          </a>
        </>
      );
    case "pdf":
      return (
        <div>
          <p className="desc margin-around">
            {I18n.t("online_service_page.please_download_pdf_here")}
          </p>
          <a
            download
            className="btn btn-tarco btn-icon"
            href={content_url}>
            <i className="fas fa-file-pdf"></i> {I18n.t("online_service_page.download")}
          </a>
        </div>
      );
    default:
      return (
        <div>
          <a
            className="btn btn-tarco btn-icon"
            href={content_url}>
            URL
          </a>
        </div>
      )
  }
}

export default OnlineServiceSolution
