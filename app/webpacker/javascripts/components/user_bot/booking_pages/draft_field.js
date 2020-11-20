"use strict"

import React from "react";

const DraftField = ({i18n, register}) => {
  return (
    <>
      <div className="field-row">
        <label>
          <input name="draft" type="radio" value="true" ref={register({ required: true })} />
          {i18n.private}
        </label>
      </div>
      <div className="field-row">
        <label>
          <input name="draft" type="radio" value="false" ref={register({ required: true })} />
          {i18n.public}
        </label>
      </div>
    </>
  )
}

export default DraftField;
