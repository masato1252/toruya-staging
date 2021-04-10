"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';

const WhyContentView = ({content, jumpTo, demo}) => (
  <div className="product-content content">
    {demo && (
      <span className="btn btn-yellow edit-mark" onClick={jumpTo}>
        <i className="fa fa-pencil-alt"></i>
        {I18n.t("action.edit")}
      </span>
    )}
    <h3 className="header centerize">
      {content.desc1}
    </h3>
    <img className="product-picture" src={content.picture_url} />
    <p>
      {content.desc2}
    </p>
  </div>
)

export default WhyContentView
