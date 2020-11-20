"use strict"

import React from "react";

const LineSharingField = ({i18n, register}) => {
  return (
    <>
      <div className="field-row">
        <label>
          <input name="line_sharing" type="radio" value="true" ref={register({ required: true })} />
          {i18n.share_in_bot}
        </label>
      </div>
      <div className="field-row">
        <label>
          <input name="line_sharing" type="radio" value="false" ref={register({ required: true })} />
          {i18n.not_share_in_bot}
        </label>
      </div>
    </>
  )
}

export default LineSharingField;
