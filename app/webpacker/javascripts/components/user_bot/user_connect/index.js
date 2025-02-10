"use strict";

import React, { useEffect } from "react";
import UserConnect from "./user_connect";
import UserShopInfo from "user_bot/user_sign_up/user_shop_info";
import FlowController from "shared/flow_controller";

const SignInSuccessfulView = ({props}) => {
  useEffect(() => {
    if (props.is_not_phone) {
      window.location.href = "/";
    } else {
      setTimeout(() => {
        window.location.href = props.toruya_line_friend_url;
      }, 5000);
    }
  }, []);

  return (
    <div>
      <h2 className="centerize">
        {props.i18n.user_connect.page_title}
      </h2>
      <h3 className="centerize final margin-around">
        <div dangerouslySetInnerHTML={{ __html: props.i18n.user_connect.message.successful_message_html  }} />
      </h3>
      <div className="margin-around centerize">
        <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
      </div>
    </div>
  )
}

export const UserConnectFlow = (props) => {
  return (
    <>
      <div className="header">
        <div className="header-title-part">
          <h1>
            <img className="logo" src={props.toruya_logo_url} />
          </h1>
        </div>
      </div>
      <FlowController>
        { ({next}) => <UserConnect props={props} next={next} /> }
        { () => <UserShopInfo
          props={props}
          finalView={<SignInSuccessfulView props={props} />}
          />
        }
      </FlowController>
    </>
  )
}

export default UserConnectFlow;
