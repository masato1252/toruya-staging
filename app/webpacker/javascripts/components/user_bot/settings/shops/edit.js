"use strict"

import React from "react";
import { useForm, Controller } from "react-hook-form";

import { ErrorMessage, BottomNavigationBar, TopNavigationBar, SelectOptions, CiricleButtonWithWord, SwitchButton } from "shared/components"
import { ShopServices } from "user_bot/api"
import I18n from 'i18n-js/index.js.erb';

const SocialAccountEdit =({props}) => {
  const onSubmit = async (data) => {
    if (formState.isSubmitting) return;

    let error, response;

    [error, response] = await ShopServices.update({
      data: _.assign( data, { attribute: props.attribute })
    })

    window.location = response.data.redirect_to
  }

  const { register, watch, setValue, setError, control, handleSubmit, formState, errors } = useForm({
    defaultValues: {
      ...props.shop,
    }
  });

  const renderCorrespondField = () => {
    switch(props.attribute) {
      case "holiday_working":
        return (
          <div className="field-row">
            日本の祝日
            <Controller
              control={control}
              name='holiday_working'
              defaultValue={watch("holiday_working")}
              render={({ onChange, value }) => (
                <SwitchButton
                  offWord="CLOSED"
                  onWord="OPEN"
                  name="holiday_working"
                  checked={value}
                  onChange={() => {
                    onChange(!value)
                  }}
                />
              )}
            />
          </div>
        );
        break
    }
  }

  return (
    <div className="form with-top-bar">
      <input type="hidden" name="id" ref={register({ required: true })} />
      <TopNavigationBar
        leading={
          <a href={Routes.index_lines_user_bot_settings_business_schedules_path({shop_id: props.shop.id})}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={'祝日'}
      />
      <div className="field-header">祝日</div>
      {renderCorrespondField()}
      <BottomNavigationBar klassName="centerize transparent">
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

export default SocialAccountEdit;
