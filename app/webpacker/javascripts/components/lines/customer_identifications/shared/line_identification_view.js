"use strict";

import React from "react";

import { LineLoginBtn } from "shared/booking";

export const LineIdentificationView = ({line_login_url}) => {
  return (
    <div className="done-view">
      <h3 className="title">
        まずはLINEでログインしてください
      </h3>

      <LineLoginBtn social_account_login_url={line_login_url}>
        <div className="message">
          サービスコンテンツは
          <br />
          LINEメッセージでお送りします
        </div>
      </LineLoginBtn>
    </div>
  )
}

export default LineIdentificationView;
