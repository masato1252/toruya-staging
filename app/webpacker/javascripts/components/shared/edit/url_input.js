"use strict"

import React from "react";

import I18n from 'i18n-js/index.js.erb';
import { isValidHttpUrl } from "libraries/helper";

const UrlInput = ({register, errors, name, placeholder, required = true}) => (
  <>
    <div className="field-row">
      <input autoFocus={true} ref={register({ required: required, validate: isValidHttpUrl })} name={name} placeholder={placeholder} className="extend" type="text" />
    </div>
    {errors[name] && errors[name].type === "validate" && <div className="field-row warning">{I18n.t("errors.invalid_url")}</div>}
  </>
)

export default UrlInput
