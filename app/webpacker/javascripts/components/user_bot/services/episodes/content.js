"use strict";

import React from "react";
import Autolinker from 'autolinker';

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
const EpisodeContent = ({episode, preview, demo, jumpByKey, light, done, service_slug, setWatchEpisodes}) => {
  if (!episode?.content_url) return <></>

  return (
    <div className="online-service-body centerize pb-6">
      <h2 className="name">
        {episode.name}
        <DemoEditButton demo={demo} jumpByKey={() => jumpByKey("name_step")} />
      </h2>
      <div className="my-4">
        <DemoEditButton demo={demo} jumpByKey={() => jumpByKey("solution_step")} />
        {(demo || preview || episode.available) ? (
          <Solution
            solution_type={episode.solution_type}
            content_url={episode.content_url}
            light={light}
          />
        ) : (
          <div className="reminder-mark">Not available</div>
        )}
      </div>
      {!demo && (
        <div className="centerize">
          <button
            disabled={done || preview || !episode.available}
            className="btn btn-tarco"
            onClick={async () => {
              const [_error, response] = await CommonServices.update({
                url: Routes.watch_episode_online_service_path({slug: service_slug, episode_id: episode.id}),
                data: {}
              })

              setWatchEpisodes(response.data.watched_episode_ids)
            }}>{I18n.t("course.mark_lesson_done")}</button>
        </div>
      )}
      {(demo || preview || episode.note) && (
        <div className="text-left break-line-content rounded mt-1">
          <DemoEditButton demo={demo} jump={() => jumpByKey("note_step")} />
          <div dangerouslySetInnerHTML={{ __html: Autolinker.link(episode.note) }} />
        </div>
      )}
    </div>
  )
}

export default EpisodeContent;
