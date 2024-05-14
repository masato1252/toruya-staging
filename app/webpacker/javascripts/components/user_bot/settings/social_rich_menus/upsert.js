"use strict";

import React, { useState } from "react";
import { useForm } from "react-hook-form";
import _ from "lodash";
import ImageUploader from "react-images-upload";
import I18n from 'i18n-js/index.js.erb';

import { BottomNavigationBar, TopNavigationBar, CircleButtonWithWord, SelectOptions } from "shared/components"
import ImageSelect from "shared/image_select"
import { isValidHttpUrl } from "libraries/helper";
import { CommonServices } from "user_bot/api";

const ActionTypeFields = ({action_type, register, index, errors, props}) => {
  if (_.includes(props.keywords, action_type)) {
    return (
      <input style={{ display: 'none' }} type="text" name={`actions[${index}].value`} defaultValue={action_type} ref={register()} />
    )
  }
  else if (action_type == "sale_page") {
    return (
      <>
        <select autoFocus={true} name={`actions[${index}].value`} ref={register({ required: true })}>
          <SelectOptions options={props.sale_pages} />
        </select>
      </>
    )
  }
  else if (action_type == "booking_page") {
    return (
      <select autoFocus={true} name={`actions[${index}].value`} ref={register({ required: true })}>
        <SelectOptions options={props.booking_pages} />
      </select>
    )
  }
  else if (action_type == "text")
    return (
      <input type="text" name={`actions[${index}].value`} ref={register({ required: true })} placeholder="value" />
    )
  else if (action_type == "uri") {
    return (
      <>
        <input type="text" name={`actions[${index}].value`} ref={register({ required: true, validate: isValidHttpUrl })} placeholder="URL" />
        {errors && errors?.actions?.length && errors?.actions[index]?.value?.type === "validate" && <div className="field-row warning">{I18n.t("errors.invalid_url")}</div>}
        <input type="text" name={`actions[${index}].desc`} ref={register({ required: true })} placeholder="desc" />
      </>
    )
  }
  else {
    return (
      <></>
    )
  }
}

const SocialRichMenuUpsert = ({props}) => {
  const [image, setImage] = useState()
  const { register, watch, handleSubmit, formState, errors, setValue } = useForm({
    defaultValues: {
      ...props.rich_menu
    }
  });

  const onSubmit = async (data) => {
    console.log("data", data)
    let error, response;

    [error, response] = await CommonServices.create({
      url: Routes.upsert_lines_user_bot_settings_social_account_social_rich_menus_path({format: "json"}),
      data: { ...data, image: image, business_owner_id: props.business_owner_id }
    })

    if (error) {
      toastr.error(error.response.data.error_message)
    }
    else {
      window.location = response.data.redirect_to;
    }
  }

  const onDrop = (image, imageDataUrl)=> {
    setImage(image[0])
    setValue("image_url", imageDataUrl)
  }

  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view">
          <div className="form with-top-bar">
            <TopNavigationBar
              leading={
                <a href={Routes.lines_user_bot_settings_social_account_social_rich_menus_path({ business_owner_id: props.business_owner_id })}>
                  <i className="fa fa-angle-left fa-2x"></i>
                </a>
              }
              title={I18n.t("settings.social_rich_menus.edit_title")}
            />
            <input type="hidden" ref={register()} name="current" />
            <input type="hidden" ref={register()} name="default" />
            <input type="hidden" ref={register()} name="social_name" />
            <div className="field-header">{I18n.t("settings.social_rich_menus.internal_name")}</div>
            <div className="field-row">
              <input
                ref={register({ required: true })}
                name="internal_name"
                type="text"
              />
            </div>
            <div className="field-header">{I18n.t("settings.social_rich_menus.bar_label")}</div>
            <div className="field-row">
              <input
                ref={register({ required: true })}
                name="bar_label"
                type="text"
              />
            </div>
            <div className="field-header">{I18n.t("settings.social_rich_menus.layout_type")}</div>
            <ImageSelect
              name="layout_type"
              handleChange={(option) => {
                setValue("layout_type", option.value)
              }}
              defaultValue={props.layout_options.find((option) => option.value === watch("layout_type"))}
              options={props.layout_options}
            />
            <input type="hidden" name="layout_type" ref={register()} />
            <div className="field-header">{I18n.t("settings.social_rich_menus.picture")}</div>
            <div className="field-row default-uploader-button-container">
              <ImageUploader
                defaultImages={watch("image_url")?.length ? [watch("image_url")] : []}
                withIcon={false}
                withPreview={true}
                withLabel={false}
                buttonText={I18n.t("settings.social_rich_menus.picture_hint")}
                singleImage={true}
                onChange={onDrop}
                imgExtension={[".jpg", ".png", ".jpeg"]}
                maxFileSize={5242880}
              />
              <input type="hidden" name="image_url" ref={register()} />
            </div>
            <div className="field-header">{I18n.t("settings.social_rich_menus.actions")}</div>
            {
              watch("layout_type") && _.times(props.layout_actions[watch("layout_type")]["size"]).map((_use, index) => {
                return (
                  <div className="field-row flex-col items-start" key={`layout-type-${index}`}>
                    <b>{props.action_labels[index]}</b>
                    <select autoFocus={true} name={`actions[${index}].type`} ref={register({ required: true })}>
                      <option value="">{I18n.t("common.select")}</option>
                      <SelectOptions options={props.action_types} />
                    </select>
                    <ActionTypeFields action_type={watch(`actions[${index}].type`)} register={register} index={index} props={props} errors={errors} />
                  </div>
                )
              }
              )
            }

            <BottomNavigationBar klassName="centerize">
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
      </div>
    </div>
  )
}

export default SocialRichMenuUpsert
