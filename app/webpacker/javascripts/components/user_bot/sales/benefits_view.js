"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';

const BenefitsView = ({benefits}) => {
  if (!benefits) return <></>

  return (
    <div className="flow-content content">
      <h3 className="header centerize">
        {"この動画セミナーで出来ること"}
      </h3>
      {benefits.map((benefit, index) => {
        return (
          <div className="flex my-4" key={`benefit-item-${index}`}>
            <i className="fa fa-check-circle"></i>
            <p className="break-line-content text-left ml-1">
              {benefit}
            </p>
          </div>
        )
      })}
    </div>
  )
}

export default BenefitsView
