"use strict"

import React from "react";
import { Controller } from "react-hook-form";
import ReactSelect from "react-select";
import I18n from 'i18n-js/index.js.erb';

const ExistingMenuField = ({register, watch, menu_group_options, control, setValue}) => {
  return (
    <>
      <Controller
        control={control}
        name="new_menu_id"
        defaultValue={watch("new_menu_id")}
        render={({ onChange, value }) => (
          <ReactSelect
            placeholder={I18n.t("common.select_a_menu")}
            options={menu_group_options}
            onChange={
              menu => {
                onChange(menu.value)
                setValue("new_menu_required_time", menu.required_time)
              }
            }
          />
        )}
      />
      <div className="field-header">{I18n.t("common.required_time")}</div>
      <div className="field-row flex-start">
        <input ref={register()} name="new_menu_required_time" type="tel" />
        {I18n.t("common.minute")}
      </div>
    </>
  )
}

export default ExistingMenuField;
