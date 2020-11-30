"use strict"

import React from "react";

const DraftField = ({i18n, register}) => {
  return (
    <>
      <label className="field-row flex-start">
        <input name="draft" type="radio" value="true" ref={register({ required: true })} />
        {i18n.private}
      </label>
      <label className="field-row flex-start">
        <input name="draft" type="radio" value="false" ref={register({ required: true })} />
        {i18n.public}
      </label>
    </>
  )
}

export default DraftField;
