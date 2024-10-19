"use strict";

import React from "react";

import { LineLoginBtn } from "shared/booking";

export const LineIdentificationView = ({line_login_url}) => {
  return (
    <div className="done-view">
      <h3 className="title">
        {I18n.t("common.line_verification.login_first_message")}
      </h3>

      <LineLoginBtn social_account_login_url={line_login_url}>
        <div className="message">
          <div dangerouslySetInnerHTML={{ __html: I18n.t("common.line_verification.service_content_message_html") }} />
        </div>
      </LineLoginBtn>
    </div>
  )
}

export default LineIdentificationView;
