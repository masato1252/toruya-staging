import React, { useState } from "react";
import TextareaAutosize from 'react-autosize-textarea';

import I18n from 'i18n-js/index.js.erb';

const FaqEdit = ({faq, handleFaqChange}) => {
  return (
    <div className="p10 margin-around border border-solid border-black rounded-md">
      <h3 className="header centerize break-line-content">
        {"よくある質問"}
      </h3>
      {faq.map((faq_item, index) => {
        return (
          <div className="flex my-4" key={`faq-item-${index}`}>
            <i className="fa fa-question-circle"></i>
            <div className="flex flex-col w-full">
              <input
                type="text"
                value={faq_item?.question || ""}
                onChange={(event) => {
                  handleFaqChange({
                    type: "SET_FAQ",
                    payload: {
                      index: index,
                      attr: "question",
                      value: event.target.value
                    }
                  })
                }}
              />
              <TextareaAutosize
                className="centerize extend with-border text-left my-4"
                rows={1}
                value={faq_item?.answer || ""}
                onChange={(event) => {
                  handleFaqChange({
                    type: "SET_FAQ",
                    payload: {
                      index: index,
                      attr: "answer",
                      value: event.target.value
                    }
                  })
                }}
              />
            </div>
            <button className="btn btn-orange" onClick={() => handleFaqChange({ type: "REMOVE_FAQ", payload: { index } }) }>
              <i className="fa fa-minus"></i>
            </button>
          </div>
        )
      })}
      <div className="action-block">
        <button className="btn btn-yellow" onClick={() => handleFaqChange({ type: "ADD_FAQ" }) }>
          {I18n.t("action.add_step")}
        </button>
      </div>
    </div>
  )
}

export default FaqEdit
