"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';

const LineVerificationWarning = ({line_settings_verified, line_verification_url}) => {

  if (line_settings_verified) return <></>

  return (
    <div className="warning">
      {I18n.t("line_verification.unverified_warning_message")}
      <div>
        <a href={line_verification_url} className="btn btn-yellow">
          {I18n.t("action.verify_line")}
        </a>
      </div>
    </div>
  )
}

export default LineVerificationWarning
