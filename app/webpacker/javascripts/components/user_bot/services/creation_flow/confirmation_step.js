"use strict";

import React, { useState } from "react";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";
import { SubmitButton } from "shared/components";

const ConfirmationStep = ({next, prev, jump, step}) => {
  const { props, dispatch, createService } = useGlobalContext()

  return (
    <div className="form settings-flow">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize">以下のサービスを作成してよろしいですか？</h3>

      <div className="action-block confirm-block">
        <SubmitButton
          handleSubmit={createService}
          submitCallback={next}
          btnWord="この設定でサービスを作成する"
        />
      </div>
    </div>
  )

}

export default ConfirmationStep
