"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';

const WhyContentView = ({content, jumpTo, demo}) => {
  const hasContent = content?.desc1?.length > 0 || content?.desc2?.length > 0 || content?.picture_url?.length > 0

  if (!hasContent) {
    return null
  }

  return (
    <div className="product-content content">
      {demo && (
        <span className="btn btn-yellow edit-mark" onClick={jumpTo}>
        <i className="fa fa-pencil-alt"></i>
        {I18n.t("action.edit")}
      </span>
    )}
    {content?.desc1?.length > 0 && (
      <h3 className="header centerize">
        {content?.desc1}
      </h3>
    )}
    {content?.picture_url?.length > 0 && <img className="product-picture" src={content?.picture_url} />}
    {content?.desc2?.length > 0 && (
      <p>
        {content?.desc2}
      </p>
    )}
  </div>
  )
}

export default WhyContentView
