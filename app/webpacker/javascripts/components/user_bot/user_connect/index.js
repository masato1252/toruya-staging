"use strict";

import React, { useEffect } from "react";
import UserConnect from "./user_connect";
import UserShopInfo from "user_bot/user_sign_up/user_shop_info";
import FlowController from "shared/flow_controller";

const SignInSuccessfulView = ({props}) => {
  useEffect(() => {
    setTimeout(() => {
      window.location = Routes.lines_user_bot_schedules_path()
    }, 3000)
  }, [])

  return (
    <div>
      <h2 className="centerize">
        {props.i18n.user_connect.page_title}
      </h2>
      <div className="whole-page-center final">
        <div dangerouslySetInnerHTML={{ __html: props.i18n.user_connect.message.successful_message_html  }} />
        <br />
        <i className="fa fa-spinner fa-spin fa-fw fa-2x"></i>
        <div className="centerize">
          Page would redirect to dashboard page automatically
        </div>
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
        { (next, _) => <UserConnect props={props} next={next} /> }
        { (_, prev) => <UserShopInfo
          props={props}
          finalView={<SignInSuccessfulView props={props} />}
          />
        }
      </FlowController>
    </>
  )
}

export default UserConnectFlow;
