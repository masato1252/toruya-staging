"use strict"

import React, { useEffect } from "react";
import { useForm, Controller } from "react-hook-form";

import { BottomNavigationBar, TopNavigationBar, CircleButtonWithWord, SwitchButton } from "shared/components"
import { BusinessScheduleServices } from "user_bot/api"
import I18n from 'i18n-js/index.js.erb';

const BusinessScheduleEdit =({props}) => {
  const { register, watch, setValue, control, handleSubmit, formState } = useForm({
    defaultValues: {
      ...props.business_schedule,
    }
  });

  const business_state = watch("business_state")
  const start_time = watch("start_time")
  const end_time = watch("end_time")

  const onSubmit = async (data) => {
    if (formState.isSubmitting) return;

    let error, response;

    [error, response] = await BusinessScheduleServices.update({
      data: _.assign( data, { business_owner_id: props.business_owner_id })
    })

    window.location = response.data.redirect_to
  }

  useEffect(() => {
    if (business_state === 'opened') {
      if (!start_time) setValue('start_time', '09:00')
      if (!end_time) setValue('end_time', '17:00')
    }
  }, [business_state])

  return (
    <div className="form with-top-bar">
      <input type="hidden" name="id" ref={register({ required: true })} />
      <input type="hidden" name="shop_id" ref={register({ required: true })} />

      <TopNavigationBar
        leading={
          <a href={Routes.index_lines_user_bot_settings_business_schedules_path(props.business_owner_id, {shop_id: props.business_schedule.shop_id})}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={I18n.t("user_bot.dashboards.settings.business_schedules.base_business_time")}
      />
      <div className="field-header">{I18n.t("common.day")}</div>
      <div className="field-row">
        {I18n.t("date.day_names")[props.business_schedule.day_of_week]}
        <Controller
          control={control}
          name='business_state'
          defaultValue={business_state}
          render={({ onChange, value }) => (
            <SwitchButton
              offWord="CLOSED"
              onWord="OPEN"
              name="business_state"
              checked={value === 'opened'}
              onChange={() => {
                onChange(value === 'opened' ? 'closed' : 'opened')
              }}
            />
          )}
        />
      </div>
      {business_state === 'opened' && (
        <>
          <div className="field-header">{I18n.t("user_bot.dashboards.settings.business_schedules.business_time")}</div>
          <div className="field-row">
            {I18n.t("user_bot.dashboards.settings.business_schedules.open_shop_time")}
            <input type="time" name="start_time" ref={register({ required: true })} />
          </div>
          <div className="field-row">
            {I18n.t("user_bot.dashboards.settings.business_schedules.close_shop_time")}
            <input type="time" name="end_time" ref={register({ required: true })} />
          </div>
          <div className="margin-around centerize">
            <div className="break-line-content">
              {I18n.t("user_bot.dashboards.settings.business_schedules.shop_open_introduction1")}
            </div>
            <br />
            <div className="break-line-content">
              {I18n.t("user_bot.dashboards.settings.business_schedules.shop_open_introduction2")}
            </div>
          </div>
        </>
      )}

      {business_state === 'closed' && (
        <div className="margin-around centerize">
          <div className="break-line-content">
            {I18n.t("user_bot.dashboards.settings.business_schedules.shop_close_introduction1")}
          </div>
          <br />
          <div className="break-line-content">
            {I18n.t("user_bot.dashboards.settings.business_schedules.shop_close_introduction2")}
          </div>
        </div>
      )}

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
  )
}

export default BusinessScheduleEdit;
