"use strict"

import React, { useEffect, useState } from "react";
import { useForm, useFieldArray, Controller } from "react-hook-form";

import { BottomNavigationBar, TopNavigationBar, CircleButtonWithWord, SwitchButton, TimePickerController } from "shared/components"
import { BusinessScheduleServices } from "user_bot/api"
import { compatRead } from "../../../../libraries/compat_api";
import I18n from 'i18n-js/index.js.erb';

const BusinessScheduleEdit =({props: initialProps}) => {
  const [readyProps, setReadyProps] = useState(
    initialProps.pageContextPath ? null : initialProps,
  );
  const [loadError, setLoadError] = useState(null);

  useEffect(() => {
    if (!initialProps.pageContextPath) return undefined;

    let cancelled = false;
    const wday = encodeURIComponent(initialProps.wday);
    compatRead(`${initialProps.pageContextPath}?wday=${wday}`)
      .then((body) => {
        if (cancelled) return;
        const form = body.data?.edit_form;
        if (!form) {
          setLoadError("Failed to load business schedule edit form");
          return;
        }
        setReadyProps({
          ...initialProps,
          ...form,
          business_schedules: form.business_schedules || [],
          business_state: form.business_state,
          wday_name: I18n.t("date.day_names")[Number(form.wday) % 7],
        });
      })
      .catch((err) => {
        if (!cancelled) setLoadError(err.message);
      });

    return () => {
      cancelled = true;
    };
  }, [initialProps]);

  const props = readyProps;
  const { register, watch, setValue, control, handleSubmit, formState } = useForm({
    defaultValues: {
      business_schedules: props?.business_schedules || [],
      business_state: props?.business_state || "closed",
    },
  });

  const business_schedule_fields = useFieldArray({
    control: control,
    name: "business_schedules"
  });

  const business_state = watch("business_state");

  useEffect(() => {
    if (!props) return;
    setValue("business_schedules", props.business_schedules || []);
    setValue("business_state", props.business_state || "closed");
  }, [props, setValue]);

  useEffect(() => {
    if (business_state !== "opened" || business_schedule_fields.fields.length !== 0) return;
    business_schedule_fields.append({
      start_time: "09:00",
      end_time: "17:00"
    });
  }, [business_state, business_schedule_fields]);

  if (loadError) return <p className="danger">{loadError}</p>;
  if (!props) return <p>{I18n.t("common.processing")}</p>;

  const onSubmit = async (data) => {
    if (formState.isSubmitting) return;

    let error, response;

    [error, response] = await BusinessScheduleServices.update({
      data: _.assign( data, { business_owner_id: props.business_owner_id, shop_id: props.shop_id, wday: props.wday })
    })

    window.location = response.data.redirect_to
  }

  return (
    <div className="form with-top-bar">
      <TopNavigationBar
        leading={
          <a href={Routes.index_lines_user_bot_settings_business_schedules_path(props.business_owner_id, { shop_id: props.shop_id })}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={I18n.t("user_bot.dashboards.settings.business_schedules.base_business_time")}
      />
      <div className="field-header">{I18n.t("common.day")}</div>
      <div className="field-row">
        {props.wday_name}
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
          {business_schedule_fields.fields.map((field, index) => {
            return (
              <div key={index} className="field-row flex-start">
                <TimePickerController
                  control={control}
                  defaultValue={watch(`business_schedules[${index}].start_time`)}
                  name={`business_schedules[${index}].start_time`}
                />
                <span>〜</span>
                <TimePickerController
                  control={control}
                  defaultValue={watch(`business_schedules[${index}].end_time`)}
                  name={`business_schedules[${index}].end_time`}
                />
                {business_schedule_fields.fields.length > 1 && (
                  <button className="btn btn-orange" onClick={() => business_schedule_fields.remove(index)}>
                    <i className="fa fa-minus"></i>
                    <span>{I18n.t("action.delete")}</span>
                  </button>
                )}
              </div>
            )
          })}
          <div className="field-row flex-start">
            <button className="btn btn-yellow" onClick={() => {
              business_schedule_fields.append({
                start_time: "09:00",
                end_time: "17:00"
              })
            }}>
              <i className="fa fa-plus"></i>
              <span>{I18n.t('action.add_more')}</span>
            </button>
          </div>
          <div className="margin-around centerize">
            <div className="break-line-content" dangerouslySetInnerHTML={{ __html: I18n.t("user_bot.dashboards.settings.business_schedules.shop_open_introduction_html") }} />
            <div>
              <img src={props.business_schedule_desc_path} className="w-full" />
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
