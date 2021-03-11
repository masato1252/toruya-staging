"use strict"

import React, { useEffect } from "react";
import { useForm, Controller } from "react-hook-form";

import { ErrorMessage, BottomNavigationBar, TopNavigationBar, SelectOptions, CiricleButtonWithWord, SwitchButton } from "shared/components"
import { ShopServices } from "user_bot/api"
import useAddress from "libraries/use_address";
import I18n from 'i18n-js/index.js.erb';

const SocialAccountEdit =({props}) => {
  const { register, watch, setValue, setError, control, handleSubmit, formState, errors } = useForm({
    defaultValues: {
      ...props.shop,
    }
  });

  const onSubmit = async (data) => {
    if (formState.isSubmitting) return;

    let error, response;

    [error, response] = await ShopServices.update({
      data: _.assign( data, { attribute: props.attribute })
    })

    window.location = response.data.redirect_to
  }

  const zip_code = watch("address_details[zip_code]");
  const address = useAddress(zip_code)

  useEffect(() => {
    setValue("address_details[region]", address?.prefecture)
    setValue("address_details[city]", address?.city)
  }, [address.city])

  const renderCorrespondField = () => {
    switch(props.attribute) {
      case "phone_number":
      case "email":
      case "website":
        return (
          <div className="field-row">
            <input ref={register} name={props.attribute} type="text" className="extend" />
          </div>
        );
      break;
      case "name":
        return (
          <>
            <div className="field-row">
              店舗名
              <input ref={register({ required: true })} name="name" type="text" />
            </div>
            <div className="field-row">
              短縮店舗名
              <input ref={register({ required: true })} name="short_name" type="text" />
            </div>
          </>
        );
        break;
      case "address":
        return (
          <>
            <div className="field-row">
              郵便番号
              <input
                ref={register({ required: true })}
                name="address_details[zip_code]"
                placeholder="1234567"
                type="tel"
              />
            </div>
            <div className="field-row">
              都道府県
              <input
                ref={register({ required: true })}
                  name="address_details[region]"
                type="text"
              />
            </div>
            <div className="field-row">
              市区町村
              <input
                ref={register({ required: true })}
                name="address_details[city]"
                type="text"
              />
            </div>
            <div className="field-row">
              続き住所
              <input
                ref={register}
                name="address_details[street1]"
                type="text"
              />
            </div>
            <div className="field-row">
              建物名／部屋番号
              <input
                ref={register}
                name="address_details[street2]"
                type="text"
              />
            </div>
          </>
        )
        break
      case "holiday_working":
        return (
          <div className="field-row">
            {I18n.t("user_bot.dashboards.settings.business_schedules.japanese_holiday_label")}
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
          <a href={props.previous_path}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={props.title}
      />
      <div className="field-header">{props.header}</div>
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
