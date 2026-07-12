"use strict"

import React, { useEffect, useState } from "react";
import { useForm } from "react-hook-form";

import { ErrorMessage, BottomNavigationBar, TopNavigationBar, SelectOptions, CircleButtonWithWord } from "shared/components"
import { SocialAccountServices } from "user_bot/api"
import { compatRead } from "../../../../libraries/compat_api";
import { responseHandler } from "libraries/helper"

const SocialAccountEdit =({props: initialProps}) => {
  const [readyProps, setReadyProps] = useState(
    initialProps.pageContextPath ? null : initialProps,
  );
  const [loadError, setLoadError] = useState(null);

  useEffect(() => {
    if (!initialProps.pageContextPath) return undefined;

    let cancelled = false;
    const attribute = encodeURIComponent(initialProps.attribute || "");
    compatRead(`${initialProps.pageContextPath}?attribute=${attribute}`)
      .then((body) => {
        if (cancelled) return;
        const form = body.data?.edit_form;
        if (!form?.social_account) {
          setLoadError("Failed to load social account edit form");
          return;
        }
        setReadyProps({
          ...initialProps,
          ...form,
          social_account: form.social_account,
          previous_path: form.previous_path,
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
  const i18n = props?.i18n;
  const { register, watch, setValue, setError, control, handleSubmit, formState, errors } = useForm({
    defaultValues: props?.social_account || {},
  });

  useEffect(() => {
    if (!props?.social_account) return;
    Object.entries(props.social_account).forEach(([key, value]) => {
      setValue(key, value);
    });
  }, [props, setValue]);

  if (loadError) {
    return (
      <div className="container-fluid">
        <div className="row">
          <div className="col-sm-6 px-0 settings-view">
            <p className="danger">{loadError}</p>
          </div>
          <div className="col-sm-6 px-0 hidden-xs preview-view" />
        </div>
      </div>
    );
  }
  if (!props?.social_account || !i18n) {
    return (
      <div className="container-fluid">
        <div className="row">
          <div className="col-sm-6 px-0 settings-view">
            <p>処理中...</p>
          </div>
          <div className="col-sm-6 px-0 hidden-xs preview-view" />
        </div>
      </div>
    );
  }

  const onSubmit = async (data) => {
    if (formState.isSubmitting) return;

    let error, response;

    [error, response] = await SocialAccountServices.update({
      data: _.assign( data, { attribute: props.attribute, business_owner_id: props.business_owner_id })
    })

    responseHandler(error, response)
  }

  const renderCorrespondField = () => {
    switch(props.attribute) {
      case "channel_id":
      case "label":
      case "channel_secret":
      case "basic_id":
      case "channel_token":
      case "login_channel_id":
      case "login_channel_secret":
        return (
          <>
            <div className="field-row">
              <input autoFocus={true} ref={register({ required: true })} name={props.attribute} placeholder={props.placeholder} className="extend" type="text" />
            </div>
            <div className="field-row hint no-border">
              {i18n.hint}
              {props.support_feature_flags.support_japanese_asset && (
                <img src={props.image_path} className="demo" />
              )}
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
          <a href={props.previous_path}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={i18n.title}
      />
      <div className="field-header">{i18n.title}</div>
      {renderCorrespondField()}
      <BottomNavigationBar klassName="centerize transparent">
        <span></span>
        <CircleButtonWithWord
          disabled={formState.isSubmitting}
          onHandle={handleSubmit(onSubmit)}
          icon={formState.isSubmitting ? <i className="fa fa-spinner fa-spin fa-2x"></i> : <i className="fa fa-save fa-2x"></i>}
          word={i18n.save}
        />
      </BottomNavigationBar>
    </div>
  )
}

export default SocialAccountEdit;
