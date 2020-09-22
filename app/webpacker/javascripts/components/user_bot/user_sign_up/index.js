"use strict";

import React from "react";
import UserIdentificationFlow from "./user_identification_flow";
import UserShopInfo from "./user_shop_info";
import FlowController from "shared/flow_controller";

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
        { (next, _) => (
          <UserIdentificationFlow
            props={props}
            next={next}
            finalView={
              <div className="whole-page-center final">
                <div dangerouslySetInnerHTML={{ __html: props.i18n.user_connect.successful_message_html }} />
                <div>
                  <a href="#" className="btn btn-tarco" onClick={next}>
                    Next
                  </a>
                </div>
              </div>} />
        )}
        { (_, prev) => <UserShopInfo props={props} prevStep={prev} /> }
      </FlowController>
    </>
  )

}

export default UserSignUp;
