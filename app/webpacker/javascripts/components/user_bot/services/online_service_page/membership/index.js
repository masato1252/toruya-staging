"use strict";

import React, { useState, useEffect, useRef } from "react";
import I18n from 'i18n-js/index.js.erb';
import Routes from 'js-routes.js';

import EpisodeContent from "user_bot/services/episodes/content";
import { InputWithEnter } from "shared/components";

import { CommonServices } from "components/user_bot/api"

const SearchBar = ({membership, setEpisodes}) => {
  const searchInput = useRef()


  const onHandleEnter = async () => {
    if (searchInput.current.value) {
      const [_error, response] = await CommonServices.get({
        url: Routes.search_episodes_online_service_path(membership.slug, searchInput.current.value,  {format: "json"})
      })

      setEpisodes(response.data.episodes)
      searchInput.current.blur()
      searchInput.current.value = ""
    }
  }

  return (
    <>
      <div className="input-group">
        <span className="input-group-addon">
          <i className="fa fa-search search-symbol" aria-hidden="true"></i>
        </span>
        <InputWithEnter
          type="search"
          ref={searchInput}
          className="form-control"
          placeholder={I18n.t("user_bot.dashboards.settings.episodes.form.search_by_name")}
          name="search"
          id="search"
          onHandleEnter={onHandleEnter}
        />
      </div>
    </>
  )
}

const TagsList = ({tags, tag, setTag}) => {
  return (
    <div className="flex flex-nowrap overflow-x-auto">
      <button
        key='all'
        className={`${tag == null ? 'bg-gray-600' : 'bg-gray-300'} btn mx-2 my-2`}
        onClick={() => setTag(null)}>
        {I18n.t("membership.all_tag")}
      </button>
      {tags.map(t=> (
        <button
          key={t}
          className={`${tag == t ? 'bg-gray-600' : 'bg-gray-300'} btn mx-2 my-2`}
          onClick={() => setTag(t)}>
          {t}
        </button>
      ))}
    </div>
  )
}

const Episode = ({episode, setEpisode}) => {
  return (
    <div
      key={`episode-${episode.id}`}
      className="p-3 flex justify-between border-0 border-b border-solid border-gray-500"
      onClick={() =>{
        setEpisode(episode)
        $("body").scrollTop(0)
      }}
    >
      <div className="">
        <img className="preview-image" src={episode.thumbnail_url || ""} />
        <span>{episode.name}</span>
      </div>
    </div>
  )
}

const MembershipPage = ({membership, default_episode, done_episode_ids, preview}) => {
  const [episode, setEpisode] = useState(default_episode)
  const [tag, setTag] = useState()
  const [episodes, setEpisodes] = useState([])
  const [watched_episode_ids, setWatchEpisodes] = useState(done_episode_ids)

  const fetchEpisodes = async () => {
    const [_error, response] = await CommonServices.get({
      url: Routes.tagged_episodes_online_service_path(membership.slug, tag, {format: "json"})
    })

    setEpisodes(response.data.episodes)
  }

  useEffect(() => {
    fetchEpisodes()
  }, [tag])

  return (
    <div className="online-service-page membership">
      <div className="online-service-header">
        {membership.company_info.logo_url ?  <img className="logo" src={membership.company_info.logo_url} /> : <h2>{membership.company_info.name}</h2> }
      </div>
      <EpisodeContent
        service_slug={membership.slug}
        episode={episode}
        preview={preview}
        done={watched_episode_ids.includes(episode?.id?.toString())}
        setWatchEpisodes={setWatchEpisodes}
      />
      {!preview  && (
        <>
          {episodes.length !== 0 && (
            <SearchBar
              membership={membership}
              setEpisodes={setEpisodes}
            />
          )} 
          {membership.tags.length && (
            <TagsList
              tags={membership.tags}
              tag={tag}
              setTag={setTag}
            />
          )}
          {episodes.map(
            (episode) => (
              <Episode
                key={`episode-${episode.id}`}
                episode={episode}
                setEpisode={setEpisode}
              />
            )
          )}
          {episodes.length === 0 && (
            <div className="reminder-mark centerize">
              {I18n.t("membership.no_episode_yet")}
            </div>
          )}
        </>)}
    </div>
  )
}

export default MembershipPage;
