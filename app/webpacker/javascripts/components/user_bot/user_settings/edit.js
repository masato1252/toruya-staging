"use strict"

import React  from "react";
import { useForm } from "react-hook-form";
import _ from "lodash";

import { BottomNavigationBar, TopNavigationBar, CircleButtonWithWord } from "shared/components"
import { CommonServices } from "user_bot/api"
import { responseHandler } from "libraries/helper";

import LineVerificationWarning from 'shared/line_verification_warning';

const UserSettingsEdit =({props}) => {
  const onSubmit = async (data) => {
    console.log(data)

    const [error, response] = await CommonServices.update({
      url: Routes.lines_user_bot_settings_user_setting_path(props.business_owner_id, {format: "json"}),
      data: _.assign(
        data,
        { attribute: props.attribute, back_path: props.back_path }
      )
    })

    responseHandler(error, response)
  }

  const { register, handleSubmit, formState } = useForm({
    defaultValues: {
      ...props.user_settings,
      line_contact_customer_name_required: String(props.user_settings.line_contact_customer_name_required),
      booking_options_menu_concept: String(props.user_settings.booking_options_menu_concept),
    }
  });

  const renderCorrespondField = () => {
    switch(props.attribute) {
      case "customer_notification_channel":
        return (
          <>
            <label className="field-row flex-start">
              <input name="customer_notification_channel" type="radio" value="email" ref={register({ required: true })} />
              {I18n.t("user_bot.dashboards.settings.user_settings.customer_notification_channel.options.email")}
            </label>
            <label className={`field-row flex-start ${!props.is_paid_user ? 'opacity-50' : ''}`}>
              <input
                name="customer_notification_channel"
                type="radio"
                value="sms"
                ref={register({ required: true })}
                disabled={!props.is_paid_user}
              />
              {I18n.t("user_bot.dashboards.settings.user_settings.customer_notification_channel.options.sms")}
              <span className="text-sm text-red-500 ml-2">
                ({I18n.t("user_bot.dashboards.settings.payment_required")})
              </span>
            </label>
            <label className={`field-row flex-start ${(!props.is_paid_user || !props.line_settings_verified) ? 'opacity-50' : ''}`}>
              <input
                name="customer_notification_channel"
                type="radio"
                value="line"
                ref={register({ required: true })}
                disabled={!props.is_paid_user || !props.line_settings_verified}
              />
              {I18n.t("user_bot.dashboards.settings.user_settings.customer_notification_channel.options.line")}
              <span className="text-sm text-red-500 ml-2">
                ({I18n.t("user_bot.dashboards.settings.payment_required")}， {I18n.t("user_bot.dashboards.settings.line_verification_required")})
              </span>
            </label>
            {!props.is_paid_user && (
              <div className="margin-around centerize">
                <a href={Routes.lines_user_bot_settings_plans_path(props.business_owner_id, { upgrade: "basic" })} className="btn btn-yellow">
                  {I18n.t("warnings.over_free_limit.upgrade_button")}
                </a>
              </div>
            )}
            {!props.line_settings_verified && (
              <div className="margin-around centerize">
                <LineVerificationWarning line_settings_verified={props.line_settings_verified} line_verification_url={props.line_verification_url} />
              </div>
            )}
          </>
        )
      case "line_contact_customer_name_required":
        return (
          <>
            <label className="field-row flex-start">
              <input name="line_contact_customer_name_required" type="radio" value="true" ref={register({ required: true })} />
              {I18n.t("user_bot.dashboards.settings.user_settings.line_contact_customer_name_required.options.require_contact_customer_name")}
            </label>
            <label className="field-row flex-start">
              <input name="line_contact_customer_name_required" type="radio" value="false" ref={register({ required: true })} />
              {I18n.t("user_bot.dashboards.settings.user_settings.line_contact_customer_name_required.options.not_require_contact_customer_name")}
            </label>
          </>
        )
      case "booking_options_menu_concept":
        return (
          <>
            <label className="field-row flex-start">
              <input name="booking_options_menu_concept" type="radio" value="true" ref={register({ required: true })} />
              {I18n.t("user_bot.dashboards.settings.user_settings.booking_options_menu_concept.options.enable_menu_concept")}
            </label>
            <label className="field-row flex-start">
              <input name="booking_options_menu_concept" type="radio" value="false" ref={register({ required: true })} />
              {I18n.t("user_bot.dashboards.settings.user_settings.booking_options_menu_concept.options.disable_menu_concept")}
            </label>
            <div className="margin-around">
              {props.support_feature_flags.support_japanese_asset && (
                <div className="m-2">
                  <img src={props.booking_option_introduction_asset_path} alt="booking_option_introduction" className="w-full" />
                </div>
              )}
              {!props.support_feature_flags.support_japanese_asset && (
                <div className="margin-around">
                  <div dangerouslySetInnerHTML={{ __html: I18n.t("settings.booking_page.form.booking_option_introduction_html") }} />
                </div>
              )}
            </div>
          </>
        )
    }
  }

  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view">
          <div className="form with-top-bar">
            <TopNavigationBar
              leading={
                <a href={ props.back_path || Routes.lines_user_bot_settings_path(props.business_owner_id)}>
                  <i className="fa fa-angle-left fa-2x"></i>
                </a>
              }
              title={I18n.t(`user_bot.dashboards.settings.user_settings.${props.attribute}.title`)}
            />
            <div className="field-header">{I18n.t(`user_bot.dashboards.settings.user_settings.${props.attribute}.title`)}</div>
            {renderCorrespondField()}
            <BottomNavigationBar klassName="centerize transparent">
              <span></span>
              <CircleButtonWithWord
                onHandle={handleSubmit(onSubmit)}
                icon={formState.isSubmitting ? <i className="fa fa-spinner fa-spin fa-2x"></i> : <i className="fa fa-save fa-2x"></i>}
                word={I18n.t("action.save")}
              />
            </BottomNavigationBar>
          </div>
        </div>
        <div className="col-sm-6 px-0 hidden-xs preview-view"></div>
      </div>
    </div>
  )
}

export default UserSettingsEdit;
