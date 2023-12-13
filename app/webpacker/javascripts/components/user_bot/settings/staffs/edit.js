"use strict"

import React, { useEffect, useState } from "react";
import { useForm } from "react-hook-form";

import { ErrorMessage, BottomNavigationBar, TopNavigationBar, SelectOptions, CircleButtonWithWord } from "shared/components"
import StaffEditComponent from "components/user_bot/sales/staff_edit";
import { CommonServices } from "user_bot/api"
import I18n from 'i18n-js/index.js.erb';

const StaffEdit = ({props}) => {
  const [staff, setStaff] = useState(props.staff)
  const { register, watch, setValue, setError, control, handleSubmit, formState, errors } = useForm({
    defaultValues: {
      ...props.staff,
    }
  });

  const onSubmit = async (data) => {
    if (formState.isSubmitting) return;

    let error, response;

    [error, response] = await CommonServices.update({
      url: Routes.lines_user_bot_settings_staff_path(props.business_owner_id, props.staff.id, {format: "json"}),
      data: _.assign( data, { attribute: props.attribute, picture: staff.picture, introduction: staff.introduction })
    })

    if (error) {
      toastr.error(error.response.data.error_message)
    }
    else {
      window.location = response.data.redirect_to
    }
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
                ref={register()}
                type="text"
                name="phonetic_last_name"
              />
              <input
                ref={register()}
                type="text"
                name="phonetic_first_name"
              />
            </div>
          </>
        );
        break
      case "phone_number":
        return (
          <>
            <div className="field-header">
              {I18n.t("common.cellphone_number")}
            </div>
            <div className="field-row">
              <input
                ref={register()}
                type="tel"
                name="phone_number"
              />
            </div>
          </>
        );
        break
      case "staff_info":
        return (
          <StaffEditComponent
            selected_staff={staff}
            handleStaffChange={(attr, value) => {
              setStaff({...staff, introduction: value})
            }}
            handlePictureChange={(picture, pictureDataUrl) => {
              setStaff({
                ...staff, picture: picture[0], picture_url: pictureDataUrl
              })
            }}
          />
        )
        break
    }
  }

  return (
    <div class="container-fluid">
      <div class="row">
        <div class="col-sm-6 px-0 settings-view">
          <div className="form with-top-bar">
            <TopNavigationBar
              leading={
                <a href={Routes.lines_user_bot_settings_staff_path(props.business_owner_id, props.staff.id)}>
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
      </div>
    </div>
  )
}

export default StaffEdit;
