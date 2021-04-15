"use strict";

import React, { useState } from "react";
import ImageUploader from "react-images-upload";
import TextareaAutosize from 'react-autosize-textarea';

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";
import WhyContentEdit from "components/user_bot/sales/why_content_edit";

const ContentSetupStep = ({step, next, prev, lastStep}) => {
  const [focus_field, setFocusField] = useState()
  const { dispatch, product_content, isContentSetup, isReadyForPreview } = useGlobalContext()

  const onDrop = (picture, pictureDataUrl)=> {
    dispatch({
      type: "SET_NESTED_ATTRIBUTE",
      payload: {
        parent_attribute: "product_content",
        attribute: "picture",
        value: picture[0]
      }
    })

    dispatch({
      type: "SET_NESTED_ATTRIBUTE",
      payload: {
        parent_attribute: "product_content",
        attribute: "picture_url",
        value: pictureDataUrl
      }
    })
  }

  return (
    <div className="form">
      <SalesFlowStepIndicator step={step} />
      <h4 className="header centerize"
        dangerouslySetInnerHTML={{ __html: I18n.t("user_bot.dashboards.sales.booking_page_creation.why_user_buy_html") }} />
        <div className="product-content-deails">
          <WhyContentEdit
            product_content={product_content}
            handleContentChange={(attr, value) => {
              dispatch({
                type: "SET_NESTED_ATTRIBUTE",
                payload: {
                  parent_attribute: "product_content",
                  attribute: attr,
                  value: value
                }
              })
            }}
            handlePictureChange={onDrop}
          />
        </div>
        <div className="action-block">
          <button onClick={prev} className="btn btn-tarco">
            {I18n.t("action.prev_step")}
          </button>
          <button onClick={() => {(isReadyForPreview()) ? lastStep(2) : next()}} className="btn btn-yellow"
            disabled={!isContentSetup()}
          >
            {I18n.t("action.next_step")}
          </button>
        </div>
      </div>
  )
}

export default ContentSetupStep
