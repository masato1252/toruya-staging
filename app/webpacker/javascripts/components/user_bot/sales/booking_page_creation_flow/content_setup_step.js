"use strict";

import React, { useState } from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";
import ImageUploader from "react-images-upload";

const ContentSetupStep = ({step, next, prev}) => {
  const { props, watch } = useGlobalContext()
  const [pictures, setPictures] = useState([]);

  const onDrop = picture => {
    setPictures([...pictures, picture]);
  }

  return (
    <div className="form">
      <SalesFlowStepIndicator step={step} />
      <ImageUploader
        {...props}
        withIcon={false}
        withPreview={true}
        withLabel={false}
        singleImage={true}
        onChange={onDrop}
        imgExtension={[".jpg", ".gif", ".png", ".gif"]}
        maxFileSize={5242880}
      />
      <div className="action-block">
        <button onClick={prev} className="btn btn-tarco">
          {I18n.t("action.prev_step")}
        </button>
        <button onClick={next} className="btn btn-yellow">
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )
}

export default ContentSetupStep
