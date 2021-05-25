"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';

const FaqView = ({faq}) => {
  if (!faq) return <></>

  return (
    <div className="content">
      <h3 className="header centerize">
        {"よくある質問"}
      </h3>
      {faq.map((faq_item, index) => {
        return (
          <div className="flex my-4 text-gray-500" key={`faq-item-${index}`}>
            <i className="fa fa-question-circle mt-1"></i>
            <div className="flex flex-col w-full text-left">
              <b className="ml-1">{faq_item.question}</b>
              <p className="break-line-content ml-1">
                {faq_item.answer}
              </p>
            </div>
          </div>
        )
      })}
    </div>
  )
}

export default FaqView
