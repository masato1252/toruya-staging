"use strict";

import React, { useEffect } from "react";
import UserIdentificationFlow from "./user_identification_flow";
import UserShopInfo from "./user_shop_info";
import FlowController from "shared/flow_controller";

const SignUpSuccessfulView = ({props}) => {
  useEffect(() => {
    setTimeout(() => {
      window.location = Routes.lines_user_bot_schedules_path()
    }, 3000)
  }, [])

  return (
    <div>
      <h2 className="centerize">
        {props.i18n.user_sign_up.page_title}
      </h2>
      <div className="whole-page-center final">
        <div dangerouslySetInnerHTML={{ __html: props.i18n.user_sign_up.message.successful_message_html }} />
        <br />
        <i className="fa fa-spinner fa-spin fa-fw fa-2x"></i>
        <div className="centerize">
          {props.i18n.user_sign_up.message.redirect_to_schedule_page}
        </div>
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
      <FlowController>
        { ({next}) => <UserIdentificationFlow props={props} next={next} /> }
        { ({prev}) => <UserShopInfo
          props={props}
          finalView={<SignUpSuccessfulView props={props} />}
          />
        }
      </FlowController>
    </>
  )

}

export default UserSignUp;
