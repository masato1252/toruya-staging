"use strict";

import React from "react";
import UserIdentificationFlow from "./user_identification_flow";

export const UserSignUp = (props) => {
  return (
    <>
      <div className="header">
        <div className="header-title-part centerize">
        </div>
      </div>
      <UserIdentificationFlow
        props={props}
        successful_view={
          <div className="whole-page-center final">
            <div dangerouslySetInnerHTML={{ __html: props.i18n.successful_message_html }} />
          </div>
        }
      />
    </>
  )

}

export default UserSignUp;
