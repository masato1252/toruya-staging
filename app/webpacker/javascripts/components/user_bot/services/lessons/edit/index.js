"use strict"

import React, { useState } from "react";
import { useForm } from "react-hook-form";
import ReactSelect from "react-select";
import _ from "lodash";

import { BottomNavigationBar, TopNavigationBar, CiricleButtonWithWord } from "shared/components"
import { CommonServices } from "user_bot/api"

import EditTextInput from "shared/edit/text_input";
import EditVideoUrl from "shared/edit/video_url";
import EditTextarea from "shared/edit/textarea_input";
import EditSelectInput from "shared/edit/select_input";
import EditSolutionInput from "shared/edit/solution_input";

const components = {
  name: EditTextInput,
  note: EditTextarea,
};

const LessonEdit =({props}) => {
  const [start_time, setStartTime] = useState(props.lesson.start_time)

  const { register, watch, setValue, control, handleSubmit, formState } = useForm({
    defaultValues: {
      ...props.lesson,
      solution_type: null
    }
  });

  const onSubmit = async (data) => {
    let error, response;

    [error, response] = await CommonServices.update({
      url: Routes.lines_user_bot_service_lesson_path(props.lesson.online_service_id, props.lesson.id, {format: 'json'}),
      data: _.assign( data, { attribute: props.attribute, chapter_id: (data.chapter_id || props.lesson.chapter_id), start_time: start_time })
    })

    window.location = response.data.redirect_to
  }

  const renderCorrespondField = () => {
    const EditComponent = components[props.attribute]

    switch (props.attribute) {
      case "chapter_id":
        return <EditSelectInput register={register} options={props.chapter_options} name="chapter_id" />
        break;
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
                  <input
                    name="start_type" type="radio" value="start_after_days"
                    checked={start_time.start_type === "start_after_days"}
                    onChange={() => {
                      setStartTime({
                        start_type: "start_after_days"
                      })
                    }}
                  />
                  {I18n.t("user_bot.dashboards.settings.course.lessons.new.after_start_x_days")}
                </div>
                {start_time.start_type === "start_after_days" && (
                  <>
                    {I18n.t("user_bot.dashboards.online_service_creation.after_bought")}
                    <input
                      type="tel"
                      value={start_time.start_after_days || ""}
                      onChange={(event) => {
                        setStartTime({
                          start_type: "start_after_days",
                          start_after_days: event.target.value
                        })
                      }} />
                    {I18n.t("user_bot.dashboards.online_service_creation.after_n_days")}
                  </>
                )}
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
      case "content_url":
        return (
          <EditSolutionInput
            solutions={props.solutions}
            attribute='content_url'
            solution_type={watch("solution_type")}
            placeholder={props.placeholder}
            register={register}
            watch={watch}
            setValue={setValue}
          />
        )
        break;
      default:
        return <EditComponent register={register} watch={watch} name={props.attribute} placeholder={props.placeholder} />;
    }
  }

  return (
    <div className="form with-top-bar">
      <TopNavigationBar
        leading={
          <a href={Routes.lines_user_bot_service_chapter_lesson_path(props.lesson.online_service_id, props.lesson.chapter_id, props.lesson.id)}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={I18n.t(`user_bot.dashboards.settings.course.lessons.form.${props.attribute}_title`)}
      />
      <div className="field-header">{I18n.t(`user_bot.dashboards.settings.course.lessons.form.${props.attribute}_title`)}</div>
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
  )
}

export default LessonEdit
