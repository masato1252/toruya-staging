"use strict"

import React  from "react";
import { useForm } from "react-hook-form";
import _ from "lodash";

import { BottomNavigationBar, TopNavigationBar, CircleButtonWithWord } from "shared/components"
import { CommonServices } from "user_bot/api"
import { responseHandler } from "libraries/helper";

const UserSettingsEdit =({props}) => {
  const onSubmit = async (data) => {
    console.log(data)

    const [error, response] = await CommonServices.update({
      url: Routes.lines_user_bot_settings_user_setting_path({format: "json"}),
      data: _.assign(
        data,
        { attribute: props.attribute }
      )
    })

    responseHandler(error, response)
  }

  const { register, handleSubmit, formState } = useForm({
    defaultValues: {
      ...props.user_settings,
      line_contact_customer_name_required: String(props.user_settings.line_contact_customer_name_required),
    }
  });

  const renderCorrespondField = () => {
    switch(props.attribute) {
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
    }
  }

  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view">
          <div className="form with-top-bar">
            <TopNavigationBar
              leading={
                <a href={Routes.lines_user_bot_settings_path(props.business_owner_id)}>
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
