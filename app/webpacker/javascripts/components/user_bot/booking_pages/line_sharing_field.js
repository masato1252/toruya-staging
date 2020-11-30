"use strict"

import React from "react";

const LineSharingField = ({i18n, register}) => {
  return (
    <>
      <label className="field-row flex-start">
        <input name="line_sharing" type="radio" value="true" ref={register({ required: true })} />
        {i18n.share_in_bot}
      </label>
      <label className="field-row flex-start">
        <input name="line_sharing" type="radio" value="false" ref={register({ required: true })} />
        {i18n.not_share_in_bot}
      </label>
    </>
  )
}

export default LineSharingField;
