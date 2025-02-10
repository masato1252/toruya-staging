"use strict";

import React, { useEffect } from "react";
import UserIdentificationFlow from "./user_identification_flow";
import UserShopInfo from "./user_shop_info";
import FlowController from "shared/flow_controller";

const SignUpSuccessfulView = ({props}) => {
  useEffect(() => {
    setTimeout(() => {
      window.location.href = "/";
    }, 2000);
  }, []);

  return (
    <div className="margin-around">
      <h2 className="centerize">
        {props.i18n.user_sign_up.page_title}
      </h2>
      <div className="whole-page-center final">
        <div dangerouslySetInnerHTML={{ __html: props.i18n.user_sign_up.message.successful_message_html }} />
      </div>
    </div>
  )
}
export const UserSignUp = (props) => {
  return (
    <>
      <div className="header">
        <div className="header-title-part">
          <h1>
            <img className="logo" src={props.toruya_logo_url} />
          </h1>
        </div>
      </div>
      <FlowController new_version={true}>
        <UserIdentificationFlow props={props} />
        <UserShopInfo
          props={props}
          finalView={<SignUpSuccessfulView props={props} />}
        />
      </FlowController>
    </>
  )

}

export default UserSignUp;
