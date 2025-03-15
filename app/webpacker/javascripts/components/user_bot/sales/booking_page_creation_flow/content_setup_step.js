"use strict";

import React, { useState, useEffect } from "react";
import ImageUploader from "react-images-upload";
import TextareaAutosize from 'react-autosize-textarea';

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";

const ContentSetupStep = ({step, next, prev, jump}) => {
  const [submitting, setSubmitting] = useState(false)
  const [focus_field, setFocusField] = useState()
  const { initial, dispatch, product_content, isContentSetup, isReadyForPreview, createDraftSalesBookingPage } = useGlobalContext()

  useEffect(() => {
    if (initial && isContentSetup()) {
      next()
    }
  }, [])

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
          {focus_field == "what_user_get_tip" && (
            <p className="centerize">{I18n.t(`user_bot.dashboards.sales.booking_page_creation.what_user_get_tip`)}</p>
          )}
          <TextareaAutosize
            className="what-user-get-tip extend with-border"
            value={product_content.desc1}
            placeholder={I18n.t("user_bot.dashboards.sales.booking_page_creation.what_user_get")}
            onFocus={(name) => setFocusField("what_user_get_tip")}
            onChange={(event) => {
              dispatch({
                type: "SET_NESTED_ATTRIBUTE",
                payload: {
                  parent_attribute: "product_content",
                  attribute: "desc1",
                  value: event.target.value
                }
              })
            }}
          />
          <ImageUploader
            defaultImages={product_content.picture_url?.length ? [product_content.picture_url] : []}
            withIcon={false}
            withPreview={true}
            withLabel={false}
            buttonText={I18n.t("user_bot.dashboards.sales.booking_page_creation.content_picture_requirement_tip")}
            singleImage={true}
            onChange={onDrop}
            imgExtension={[".jpg", ".png", ".jpeg", ".gif"]}
            maxFileSize={5242880}
          />
          {focus_field == "what_buyer_future_tip" && <p className="centerize">{I18n.t(`user_bot.dashboards.sales.booking_page_creation.what_buyer_future_tip`)}</p>}
          <TextareaAutosize
            className="extend with-border"
            value={product_content.desc2}
            placeholder={I18n.t("user_bot.dashboards.sales.booking_page_creation.what_buyer_future")}
            onFocus={(name) => setFocusField("what_buyer_future_tip")}
            onChange={(event) => {
              dispatch({
                type: "SET_NESTED_ATTRIBUTE",
                payload: {
                  parent_attribute: "product_content",
                  attribute: "desc2",
                  value: event.target.value
                }
              })
            }}
          />
        </div>
        <div className="action-block">
          <button onClick={prev} className="btn btn-tarco">
            {I18n.t("action.prev_step")}
          </button>
          <button
            className="btn btn-gray"
            disabled={submitting}
            onClick={async () => {
              if (submitting) return;
              setSubmitting(true)
              await createDraftSalesBookingPage()
            }}>
            {submitting ? (
              <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
            ) : (
              I18n.t("action.save_as_draft")
            )}
          </button>
          <button onClick={() => {(isReadyForPreview()) ? jump(7) : next()}} className="btn btn-yellow">
            {I18n.t("action.next_step")}
          </button>
        </div>
      </div>
  )
}

export default ContentSetupStep
