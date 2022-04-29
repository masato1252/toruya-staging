import React from "react";
import ImageUploader from "react-images-upload";
import TextareaAutosize from 'react-autosize-textarea';

import I18n from 'i18n-js/index.js.erb';

const EditMessageTemplate = ({service_name, message_template, handleMessageTemplateChange, handlePictureChange}) => {
  return (
    <div className="product-content-deails">
      <ImageUploader
        defaultImages={message_template?.picture_url?.length ? [message_template.picture_url] : []}
        withIcon={false}
        withPreview={true}
        withLabel={false}
        buttonText={I18n.t("user_bot.dashboards.online_service_creation.content_picture_requirement_tip")}
        singleImage={true}
        onChange={handlePictureChange}
        imgExtension={[".jpg", ".png", ".jpeg", ".gif"]}
        maxFileSize={5242880}
      />
    </div>
  )
}

export default EditMessageTemplate
