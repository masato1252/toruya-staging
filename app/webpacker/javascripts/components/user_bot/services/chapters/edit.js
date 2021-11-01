"use strict"

import React, { useState, useRef, useEffect } from "react";
import { useForm, Controller } from "react-hook-form";

import Routes from 'js-routes.js'
import { CommonServices } from "user_bot/api"
import I18n from 'i18n-js/index.js.erb';
import { ErrorMessage, BottomNavigationBar, TopNavigationBar, CiricleButtonWithWord } from "shared/components"

const ChapterEdit =({props}) => {
  const { register, watch, setValue, setError, control, handleSubmit, formState, errors } = useForm({
    defaultValues: {
      ...props.chapter
    }
  });

  const onSubmit = async (data) => {
    let error, response;

    if (props.chapter.id) {
      [error, response] = await CommonServices.update({
        url: Routes.lines_user_bot_service_chapter_path(props.chapter.online_service_id, props.chapter.id, {format: "json"}),
        data: _.assign(data, {
        })
      })
    }
    else {
      [error, response] = await CommonServices.create({
        url: Routes.lines_user_bot_service_chapters_path(props.chapter.online_service_id, {format: "json"}),
        data: _.assign(data, {
        })
      })
    }

    window.location = response.data.redirect_to
  }

  const renderCorrespondField = () => {
    return (
      <div className="field-row">
        <input ref={register} name="name" type="text" />
      </div>
    );
  }

  return (
    <div className="form with-top-bar">
      <TopNavigationBar
        leading={
          <a href={Routes.lines_user_bot_service_chapters_path(props.chapter.online_service_id)}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={I18n.t("user_bot.dashboards.settings.course.chapters.form.name_title")}
      />
      <div className="field-header">{I18n.t("user_bot.dashboards.settings.course.chapters.form.name_title")}</div>
      {renderCorrespondField()}
      <BottomNavigationBar klassName="centerize transparent">
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

export default ChapterEdit;
