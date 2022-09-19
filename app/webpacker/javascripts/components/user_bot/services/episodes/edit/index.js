"use strict"

import React, { useState } from "react";
import { useForm } from "react-hook-form";
import _ from "lodash";

import { BottomNavigationBar, TopNavigationBar, CiricleButtonWithWord } from "shared/components"
import { CommonServices } from "user_bot/api"

import EditTextInput from "shared/edit/text_input";
import EditTextarea from "shared/edit/textarea_input";
import EditSolutionInput from "shared/edit/solution_input";
import EditTagsInput from "user_bot/services/episodes/shared/edit_tags_input";
import EpisodeContent from "user_bot/services/episodes/content";

const components = {
  name: EditTextInput,
  note: EditTextarea,
};

const EpisodeEdit =({props}) => {
  const [start_time, setStartTime] = useState(props.episode.start_time)
  const [end_time, setEndTime] = useState(props.episode.end_time)
  const [tags, setTags] = useState(props.episode.tags || [])
  const [new_tag, setNewTag] = useState()

  const { register, watch, setValue, handleSubmit, formState, errors } = useForm({
    defaultValues: {
      ...props.episode
    }
  });

  const onSubmit = async (data) => {
    let response;

    [_, response] = await CommonServices.update({
      url: Routes.lines_user_bot_service_episode_path(props.episode.online_service_id, props.episode.id, {format: 'json'}),
      data: _.assign( data, { attribute: props.attribute, start_time: start_time, end_time: end_time, tags: tags })
    })

    window.location = response.data.redirect_to
  }

  const renderCorrespondField = () => {
    const EditComponent = components[props.attribute]

    switch (props.attribute) {
      case "start_time":
        return (
          <div className="centerize">
            <div className="margin-around">
              <label className="">
                <input name="start_type" type="radio" value="never"
                  checked={start_time.start_type === "now"}
                  onChange={() => {
                    setStartTime({
                      start_type: "now",
                    })
                  }}
                />
                {I18n.t("user_bot.dashboards.settings.course.lessons.new.right_after_service_start")}
              </label>
            </div>

            <div className="margin-around">
              <label className="">
                <div>
                  <input name="start_type" type="radio" value="start_at"
                    checked={start_time.start_type === "start_at"}
                    onChange={() => {
                      setStartTime({
                        start_type: "start_at",
                      })
                    }}
                  />
                  {I18n.t("user_bot.dashboards.settings.course.lessons.new.start_on_specific_day")}
                </div>
                {start_time.start_type === "start_at" && (
                  <input
                    name="start_time_date_part"
                    type="date"
                    value={start_time.start_time_date_part || ""}
                    onChange={(event) => {
                      setStartTime({
                        start_type: "start_at",
                        start_time_date_part: event.target.value
                      })
                    }}
                  />
                )}
              </label>
            </div>
          </div>
        )
      case "end_time":
        return (
          <div className="centerize">
            <div className="margin-around">
              <label className="">
                <div>
                  <input name="end_type" type="radio" value="end_at"
                    checked={end_time.end_type === "end_at"}
                    onChange={() => {
                      setEndTime({
                        end_type: "end_at"
                      })
                    }}
                  />
                  {I18n.t("user_bot.dashboards.online_service_creation.expire_at")}
                </div>
                {end_time.end_type === "end_at" && (
                  <input
                    name="end_time_date_part"
                    type="date"
                    value={end_time.end_time_date_part || ""}
                    onChange={(event) => {
                      setEndTime({
                        end_type: "end_at",
                        end_time_date_part: event.target.value
                      })
                    }}
                  />
                )}
              </label>
            </div>

            <div className="margin-around">
              <label className="">
                <input name="end_type" type="radio" value="never"
                  checked={end_time.end_type === "never"}
                  onChange={() => {
                    setEndTime({
                      end_type: "never",
                    })
                  }}
                />
                {I18n.t("user_bot.dashboards.online_service_creation.never_expire")}
              </label>
            </div>
          </div>
        )
      case "content_url":
        return (
          <EditSolutionInput
            solutions={props.solutions}
            attribute='content_url'
            solution_type={watch("solution_type")}
            placeholder={props.placeholder}
            register={register}
            errors={errors}
            watch={watch}
            setValue={setValue}
          />
        )
      case "tags":
        return (
          <div className="centerize">
            <EditTagsInput
              new_tag={new_tag}
              tags={tags}
              existing_tags={props.online_service.tags}
              setNewTag={setNewTag}
              setTags={setTags}
            />
          </div>
        )
      default:
        {/*name,  note */}
        return <EditComponent register={register} watch={watch} name={props.attribute} placeholder={props.placeholder} />;
    }
  }

  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0">
          <div className="form with-top-bar">
            <TopNavigationBar
              leading={
                <a href={Routes.lines_user_bot_service_episode_path(props.episode.online_service_id, props.episode.id)}>
                  <i className="fa fa-angle-left fa-2x"></i>
                </a>
              }
              title={I18n.t(`user_bot.dashboards.settings.membership.episodes.title`)}
            />
            <div className="field-header">{I18n.t(`user_bot.dashboards.settings.episodes.form.${props.attribute}_subtitle`)}</div>
            {renderCorrespondField()}

            <BottomNavigationBar klassName="centerize">
              <span></span>
              <CiricleButtonWithWord
                disabled={formState.isSubmitting}
                onHandle={handleSubmit(onSubmit)}
                icon={formState.isSubmitting ? <i className="fa fa-spinner fa-spin fa-2x"></i> : <i className="fa fa-save fa-2x"></i>}
                word={I18n.t("action.save")}
              />
            </BottomNavigationBar>
          </div>
        </div>

        <div className="col-sm-6 px-0 hidden-xs">
          {
            ['name', 'content_url', 'note'].includes(props.attribute) && (
              <div className="fake-mobile-layout">
                <EpisodeContent
                  demo={false}
                  preview={true}
                  episode={_.merge(props.episode, { [props.attribute]: watch(props.attribute) })}
                />
              </div>
            )
          }
        </div>
      </div>
    </div>
  )
}

export default EpisodeEdit
