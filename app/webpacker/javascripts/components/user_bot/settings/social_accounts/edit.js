"use strict"

import React from "react";
import { useForm } from "react-hook-form";

import { ErrorMessage, BottomNavigationBar, TopNavigationBar, SelectOptions, CiricleButtonWithWord } from "shared/components"
import { SocialAccountServices } from "user_bot/api"

const SocialAccountEdit =({props}) => {
  const i18n = props.i18n;

  const onSubmit = async (data) => {
    if (isSubmitting.submitting) return;

    let error, response;

    [error, response] = await SocialAccountServices.update({
      data: _.assign( data, { attribute: props.attribute })
    })

    window.location = response.data.redirect_to
  }

  const { register, watch, setValue, setError, control, handleSubmit, formState, errors } = useForm({
    defaultValues: {
      ...props.social_account,
    }
  });

  const renderCorrespondField = () => {
    switch(props.attribute) {
      case "channel_id":
      case "label":
      case "channel_secret":
      case "basic_id":
      case "channel_token":
        return (
          <>
            <div className="field-row">
              <input autoFocus={true} ref={register({ required: true })} name={props.attribute} placeholder={props.placeholder} className="extend" type="text" />
            </div>
            <div className="field-row hint no-border">
              {i18n.hint}
              <img src={props.image_path} className="demo" />
            </div>
          </>
        );
        break
    }
  }

  return (
    <div className="form with-top-bar">
      <TopNavigationBar
        leading={
          <a href={Routes.lines_user_bot_settings_social_account_path()}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={i18n.title}
      />
      <div className="field-header">{i18n.title}</div>
      {renderCorrespondField()}
      <BottomNavigationBar klassName="centerize transparent">
        <span></span>
        <CiricleButtonWithWord
          onHandle={handleSubmit(onSubmit)}
          icon={<i className="fa fa-save fa-2x"></i>}
          word={i18n.save}
        />
      </BottomNavigationBar>
    </div>
  )
}

export default SocialAccountEdit;
