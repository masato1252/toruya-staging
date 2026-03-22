"use strict"

import React, { useState } from "react";
import { useForm } from "react-hook-form";
import { TopNavigationBar, BottomNavigationBar, CircleButtonWithWord } from "shared/components";
import { CommonServices } from "user_bot/api";
import I18n from 'i18n-js/index.js.erb';

const EventForm = ({ props }) => {
  const isEdit = !!props.event?.id;
  const { register, handleSubmit, formState } = useForm({
    defaultValues: {
      title: props.event?.title || "",
      slug: props.event?.slug || "",
      description: props.event?.description || "",
      start_at: props.event?.start_at ? props.event.start_at.slice(0, 16) : "",
      end_at: props.event?.end_at ? props.event.end_at.slice(0, 16) : "",
      published: props.event?.published || false,
    }
  });

  const onSubmit = async (data) => {
    if (formState.isSubmitting) return;

    const [error, response] = await (isEdit
      ? CommonServices.update({ url: props.action_url, data })
      : CommonServices.create({ url: props.action_url, data })
    );

    if (error) {
      toastr.error(error.response?.data?.error_message || "エラーが発生しました");
    } else {
      window.location = response.data.redirect_to;
    }
  };

  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view">
          <div className="form with-top-bar">
            <TopNavigationBar
              leading={
                <a href={Routes.lines_user_bot_events_path(props.business_owner_id)}>
                  <i className="fa fa-angle-left fa-2x"></i>
                </a>
              }
              title={isEdit ? "イベント編集" : "イベント作成"}
            />

            <div className="field-header">タイトル <span className="text-red-500">*</span></div>
            <div className="field-row">
              <input ref={register({ required: true })} name="title" type="text" placeholder="イベントタイトル" className="form-control" />
            </div>

            <div className="field-header">スラッグ（URL用英数字） <span className="text-red-500">*</span></div>
            <div className="field-row">
              <input ref={register({ required: true, pattern: /^[a-z0-9\-]+$/ })} name="slug" type="text" placeholder="event-slug-2026" className="form-control" />
              <small className="text-gray-500">/events/[スラッグ] で公開されます</small>
            </div>

            <div className="field-header">概要</div>
            <div className="field-row">
              <textarea ref={register()} name="description" rows={4} placeholder="イベントの概要説明" className="form-control" />
            </div>

            <div className="field-header">開催開始日時</div>
            <div className="field-row">
              <input ref={register()} name="start_at" type="datetime-local" className="form-control" />
            </div>

            <div className="field-header">開催終了日時</div>
            <div className="field-row">
              <input ref={register()} name="end_at" type="datetime-local" className="form-control" />
            </div>

            <div className="field-header">公開設定</div>
            <div className="field-row">
              <label className="flex items-center gap-2">
                <input ref={register()} name="published" type="checkbox" />
                公開する
              </label>
            </div>

            <BottomNavigationBar klassName="centerize transparent">
              <span></span>
              <CircleButtonWithWord
                disabled={formState.isSubmitting}
                onHandle={handleSubmit(onSubmit)}
                icon={formState.isSubmitting ? <i className="fa fa-spinner fa-spin fa-2x"></i> : <i className="fa fa-save fa-2x"></i>}
                word={I18n.t("action.save")}
              />
            </BottomNavigationBar>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EventForm;
