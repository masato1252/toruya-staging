import React, { useState } from "react";
import TextareaAutosize from 'react-autosize-textarea';

import I18n from 'i18n-js/index.js.erb';

const BenefitsEdit = ({benefits, handleBenefitsChange}) => {
  return (
    <div className="p10 margin-around border border-solid border-black rounded-md">
      <h3 className="header centerize break-line-content">
        {I18n.t('user_bot.dashboards.sales.form.benefits_content_header')}
      </h3>
      {benefits.map((benefit, index) => {
        return (
          <div className="flex my-4" key={`benefit-item-${index}`}>
            <i className="fa fa-check-circle"></i>
            <TextareaAutosize
              className="centerize extend with-border text-left"
              rows={1}
              value={benefit}
              onChange={(event) => {
                handleBenefitsChange({
                  type: "SET_BENEFITS",
                  payload: {
                    index: index,
                    value: event.target.value
                  }
                })
              }}
            />
            <button className="btn btn-orange" onClick={() => handleBenefitsChange({ type: "REMOVE_BENEFIT", payload: { index } }) }>
              <i className="fa fa-minus"></i>
            </button>
          </div>
        )
      })}
      <div className="action-block">
        <button className="btn btn-yellow" onClick={() => handleBenefitsChange({ type: "ADD_BENEFIT" }) }>
          {I18n.t('user_bot.dashboards.sales.form.add_benefit')}
        </button>
      </div>
    </div>
  )
}

export default BenefitsEdit
