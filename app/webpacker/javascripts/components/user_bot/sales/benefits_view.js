"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';

const BenefitsView = ({benefits}) => {
  if (!benefits) return <></>

  return (
    <div className="content">
      <h3 className="header centerize">
        {I18n.t('user_bot.dashboards.sales.form.benefits_content_header')}
      </h3>
      {benefits.map((benefit, index) => {
        return (
          <div className="flex my-4 text-gray-500" key={`benefit-item-${index}`}>
            <i className="fa fa-check-circle mt-1"></i>
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
