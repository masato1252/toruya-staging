import React, { useState } from "react";
import ImageUploader from "react-images-upload";
import TextareaAutosize from 'react-autosize-textarea';

import I18n from 'i18n-js/index.js.erb';

const WhyContentEdit = ({product_content, handleContentChange, handlePictureChange}) => {
  const [focus_field, setFocusField] = useState()

  return (
    <>
      {focus_field == "what_user_get_tip" && (
        <p className="centerize">{I18n.t(`user_bot.dashboards.sales.booking_page_creation.what_user_get_tip`)}</p>
      )}
      <TextareaAutosize
        className="what-user-get-tip extend with-border"
        value={product_content.desc1}
        placeholder={I18n.t("user_bot.dashboards.sales.booking_page_creation.what_user_get")}
        onFocus={(name) => setFocusField("what_user_get_tip")}
        onChange={(event) => {
          handleContentChange("desc1", event.target.value)
        }}
      />
      <div className="default-uploader-button-container">
        <ImageUploader
          defaultImages={product_content.picture_url?.length ? [product_content.picture_url] : []}
          withIcon={false}
          withPreview={true}
          withLabel={false}
          buttonText={I18n.t("user_bot.dashboards.sales.booking_page_creation.content_picture_requirement_tip")}
          singleImage={true}
          onChange={handlePictureChange}
          imgExtension={[".jpg", ".png", ".jpeg", ".gif"]}
          maxFileSize={5242880}
        />
      </div>
      {focus_field == "what_buyer_future_tip" && <p className="centerize mt-2 warning-text">{I18n.t(`user_bot.dashboards.sales.booking_page_creation.what_buyer_future_tip`)}</p>}
      <TextareaAutosize
        className="extend with-border"
        value={product_content.desc2}
        placeholder={I18n.t("user_bot.dashboards.sales.online_service_creation.what_buyer_future")}
        onFocus={(name) => setFocusField("what_buyer_future_tip")}
        onChange={(event) => {
          handleContentChange("desc2", event.target.value)
        }}
      />
    </>
  )
}

export default WhyContentEdit
