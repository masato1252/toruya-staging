"use strict";

import React from "react";
import UserConnect from "./user_connect";
import UserShopInfo from "user_bot/user_sign_up/user_shop_info";
import FlowController from "shared/flow_controller";

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
        { (_, prev) => <UserShopInfo props={props} /> }
      </FlowController>
    </>
  )

}

export default UserConnectFlow;
