"use strict"

import React, { useEffect } from "react";
import { useForm } from "react-hook-form";

import { ErrorMessage, BottomNavigationBar, TopNavigationBar, SelectOptions, CircleButtonWithWord } from "shared/components"
import { UsersServices } from "user_bot/api"
import I18n from 'i18n-js/index.js.erb';
import useAddress from "libraries/use_address";
import SaleDemoPage from "user_bot/sales/demo";

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
      data: _.assign( data, { attribute: props.attribute, logo: data["logo"]?.[0], business_owner_id: props.business_owner_id })
    })

    if (error) {
      toastr.error(error.response.data.error_message)
    }
    else {
      window.location = response.data.redirect_to
    }
  }

  const _handleImageChange = (e) => {
    e.preventDefault();

    let reader = new FileReader();
    let file = e.target.files[0];

    reader.onloadend = () => {
      setValue("logo_url", reader.result)
    }

    reader.readAsDataURL(file)
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
                placeholder={I18n.t("common.last_name")}
                name="last_name"
                type="text"
              />
              <input
                ref={register({ required: true })}
                placeholder={I18n.t("common.first_name")}
                name="first_name"
                type="text"
              />
            </div>
            {props.support_feature_flags.support_phonetic_name && (
              <>
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
            )}
          </>
        );
        break
      case "website":
      case "company_name":
      case "company_email":
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
      case "logo":
        return (
          <div className="field-row justify-center">
            <div className="margin-around">
              <input type="hidden" name="logo_url" ref={register} />
              <img src={watch("logo_url")} className="logo" />
            </div>
            <input ref={register} onChange={_handleImageChange} type="file" name="logo" accept="image/png,image/gif" />
            <p className="margin-around desc centerize">
              {I18n.t("user_bot.dashboards.settings.shop.logo_limit_description")}
            </p>
          </div>
        )
        break;
      case "company_phone_number":
        return (
          <>
            <div className="field-header">{I18n.t("common.phone_number")}</div>
            <div className="field-row">
              <input
                ref={register}
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
                ref={register()}
                name={`${props.attribute}[zip_code]`}
                placeholder="1234567"
                type="tel"
              />
            </div>
            <div className="field-header">{I18n.t("common.address_region")}</div>
            <div className="field-row">
              <input
                ref={register()}
                name={`${props.attribute}[region]`}
                type="text"
              />
            </div>
            <div className="field-row">
              <input
                ref={register()}
                name={`${props.attribute}[city]`}
                type="text"
                className="expanded"
              />
            </div>
            <div className="field-row">
              <input
                ref={register()}
                name={`${props.attribute}[street1]`}
                type="text"
                className="expanded"
              />
            </div>
            <div className="field-row">
              <input
                ref={register()}
                name={`${props.attribute}[street2]`}
                type="text"
                className="expanded"
              />
            </div>
          </>
        )
        break
    }
  }

  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view">
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
              <CircleButtonWithWord
                disabled={formState.isSubmitting}
                onHandle={handleSubmit(onSubmit)}
                icon={formState.isSubmitting ? <i className="fa fa-spinner fa-spin fa-2x"></i> : <i className="fa fa-save fa-2x"></i>}
                word={I18n.t("action.save")}
              />
            </BottomNavigationBar>
          </div>
        </div>

        <div className="col-sm-6 px-0 hidden-xs preview-view">
          {['company_name'].includes(props.attribute) && (
            <div className="fake-mobile-layout">
              <SaleDemoPage
                shop={{...props.profile, [props.attribute]: watch(props.attribute)}}
              />
            </div>
          )}
          {['company_phone_number'].includes(props.attribute) && (
            <div className="fake-mobile-layout">
              <SaleDemoPage
                shop={{...props.profile, company_phone_number: watch(props.attribute), phone_number: watch(props.attribute)}}
              />
            </div>
          )}
          {['logo'].includes(props.attribute) && (
            <div className="fake-mobile-layout">
              <SaleDemoPage
                shop={{...props.profile, logo_url: watch("logo_url")}}
              />
            </div>
          )}
          {['company_address_details'].includes(props.attribute) && (
            <div className="fake-mobile-layout">
              <SaleDemoPage
                shop={{...props.profile, address: `〒${watch('company_address_details[zip_code]')}${watch('company_address_details[region]')}${watch('company_address_details[city]')}${watch('company_address_details[street1]')}${watch('company_address_details[street2]')}`}}
              />
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default ProfileEdit;
