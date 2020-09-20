"use strict";

import React from "react";
import UserIdentificationFlow from "./user_identification_flow";
import UserShopInfo from "./user_shop_info";
import FlowController from "shared/flow_controller";

export const UserSignUp = (props) => {
  return (
    <>
      <div className="header">
        <div className="header-title-part centerize">
        </div>
      </div>
      <FlowController>
        { (next, _) => (
          <UserIdentificationFlow
            props={props}
            finalView={
              <div className="whole-page-center final">
                <div dangerouslySetInnerHTML={{ __html: props.i18n.successful_message_html }} />
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
