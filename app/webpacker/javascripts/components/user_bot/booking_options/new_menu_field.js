"use strict"

import React from "react";
import { Controller } from "react-hook-form";
import ReactSelect from "react-select";

const NewMenuField = ({i18n, register, watch, menu_group_options, control, setValue}) => {
  return (
    <>
      <Controller
        control={control}
        name="new_menu_id"
        defaultValue={watch("new_menu_id")}
        render={({ onChange, value }) => (
          <ReactSelect
            placeholder={i18n.select_a_menu}
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
      <div className="field-header">{i18n.required_time}</div>
      <div className="field-row flex-start">
        <input ref={register()} name="new_menu_required_time" type="tel" />
        {i18n.minute}
      </div>
    </>
  )
}

export default NewMenuField;
