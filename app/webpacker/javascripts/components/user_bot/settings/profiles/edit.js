"use strict"

import React, { useEffect } from "react";
import { useForm } from "react-hook-form";

import { ErrorMessage, BottomNavigationBar, TopNavigationBar, SelectOptions, CiricleButtonWithWord } from "shared/components"
import { UsersServices } from "user_bot/api"
import I18n from 'i18n-js/index.js.erb';
import useAddress from "libraries/use_address";

const ProfileEdit =({props}) => {
  const { register, watch, setValue, setError, control, handleSubmit, formState, errors } = useForm({
    defaultValues: {
      ...props.profile,
    }
  });

  const address = useAddress(watch(`${props.attribute}[zip_code]`))
  useEffect(() => {
    setValue(`${props.attribute}[region]`, address?.prefecture)
    setValue(`${props.attribute}[city]`, address?.city)
  }, [address.city])

  const onSubmit = async (data) => {
    if (formState.isSubmitting) return;

    let error, response;

    [error, response] = await UsersServices.updateProfile({
      data: _.assign( data, { attribute: props.attribute })
    })

    window.location = response.data.redirect_to
  }

  const renderCorrespondField = () => {
    switch(props.attribute) {
      case "name":
        return (
          <>
            <div className="field-header">
              {I18n.t("common.name2")}
            </div>
            <div className="field-row">
              <input
                ref={register({ required: true })}
                name="last_name"
                type="text"
              />
              <input
                ref={register({ required: true })}
                name="first_name"
                type="text"
              />
            </div>
            <div className="field-header">
              {I18n.t("common.phonetic_name")}
            </div>
            <div className="field-row">
              <input
                ref={register({ required: true })}
                type="text"
                name="phonetic_last_name"
              />
              <input
                ref={register({ required: true })}
                type="text"
                name="phonetic_first_name"
              />
            </div>
          </>
        );
        break
      case "website":
      case "company_name":
        return (
          <>
            <div className="field-header">{I18n.t(`common.${props.attribute}`)}</div>
            <div className="field-row">
              <input
                ref={register({ required: true })}
                name={props.attribute}
                type="text"
              />
            </div>
          </>
        );
        break
      case "company_phone_number":
        return (
          <>
            <div className="field-header">{I18n.t("common.phone_number")}</div>
            <div className="field-row">
              <input
                ref={register({ required: true })}
                name="company_phone_number"
                type="tel"
              />
            </div>
          </>
        );
        break
      case "company_address_details":
        return (
          <>
            <div className="field-header">{I18n.t("common.zip_code")}</div>
            <div className="field-row">
              <input
                ref={register({ required: true })}
                name={`${props.attribute}[zip_code]`}
                placeholder="1234567"
                type="tel"
              />
            </div>
            <div className="field-header">{I18n.t("common.address_region")}</div>
            <div className="field-row">
              <input
                ref={register({ required: true })}
                name={`${props.attribute}[region]`}
                type="text"
              />
            </div>
            <div className="field-row">
              <input
                ref={register({ required: true })}
                name={`${props.attribute}[city]`}
                type="text"
                className="expaned"
              />
            </div>
            <div className="field-row">
              <input
                ref={register()}
                name="street1"
                name={`${props.attribute}[street1]`}
                type="text"
                className="expaned"
              />
            </div>
            <div className="field-row">
              <input
                ref={register()}
                name={`${props.attribute}[street2]`}
                type="text"
                className="expaned"
              />
            </div>
          </>
        )
        break
    }
  }

  return (
    <div className="form with-top-bar">
      <TopNavigationBar
        leading={
          <a href={props.previous_path}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={props.title}
      />
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

export default ProfileEdit;
