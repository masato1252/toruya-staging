"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';
import Routes from 'js-routes.js'
import { DemoEditButton } from 'shared/components';
import { CommonServices } from "user_bot/api";

import Solution from "../online_service_page/solution";
// episode:
// {
//   name: $name,
//   note: $note,
//   solution_type: video/pdf,
//   content_url: $url
// }
//
// demo: true/false
// jump: $function
// light: true/false
const EpisodeContent = ({course, episode, preview, demo, jumpByKey, light}) => {
  if (!episode) return <></>

  return (
    <div className="online-service-body centerize">
      <h2 className="name">
        {episode.name}
        <DemoEditButton demo={demo} jumpByKey={() => jumpByKey("name_step")} />
      </h2>
      <div className="my-4">
        <DemoEditButton demo={demo} jumpByKey={() => jumpByKey("solution_step")} />
        {demo || preview ? (
          <Solution
            solution_type={episode.solution_type}
            content_url={episode.content_url}
            light={light}
          />
        ) : (
          <div className="reminder-mark">
            {I18n.t("course.episode_start_on")}{episode.customer_start_time}
          </div>
        )}
      </div>
      {demo || preview && (
        <div className="text-left break-line-content border border-solid p-3 rounded mt-1">
          <DemoEditButton demo={demo} jump={() => jumpByKey("note_step")} />
          {episode.note}
        </div>
      )}
    </div>
  )
}

export default EpisodeContent;
