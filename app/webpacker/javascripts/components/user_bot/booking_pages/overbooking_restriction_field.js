"use strict"

import React from "react";

const OverbookingRestrictionField = ({i18n, register}) => {
  return (
    <>
      <label className="field-row flex-start">
        <input name="overbooking_restriction" type="radio" value="true" ref={register({ required: true })} />
        {i18n.not_allow_overbooking_label}
      </label>
      <label className="field-row flex-start">
        <input name="overbooking_restriction" type="radio" value="false" ref={register({ required: true })} />
        {i18n.allow_overbooking_label}
      </label>
    </>
  )
}

export default OverbookingRestrictionField;
