"use strict"

import React from "react";

const SocialAccountSkippableField = ({i18n, register}) => {
  return (
    <>
      <label className="field-row flex-start">
        <input name="social_account_skippable" type="radio" value="true" ref={register({ required: true })} />
        {i18n.social_account_skippable_label}
      </label>
      <label className="field-row flex-start">
        <input name="social_account_skippable" type="radio" value="false" ref={register({ required: true })} />
        {i18n.not_social_account_skippable_label}
      </label>
    </>
  )
}

export default SocialAccountSkippableField;
