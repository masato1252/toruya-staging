"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';

const StaffView = ({staff, jumpTo, demo}) => (
  <div className="staff-content content">
    {demo && (
      <span className="btn btn-yellow edit-mark" onClick={jumpTo}>
        <i className="fa fa-pencil-alt"></i>
        {I18n.t("action.edit")}
      </span>
    )}
    <img className="staff-picture" src={staff?.picture_url} />
    <b className="name">{staff?.name}</b>
    <p>
      {staff?.introduction}
    </p>
  </div>
)

export default StaffView
