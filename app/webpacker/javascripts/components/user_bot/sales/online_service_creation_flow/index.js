"use strict";

import React from "react";
import FlowController from "shared/flow_controller";
import { GlobalProvider } from "./context/global_state"
import OnlineServiceSelectionStep from "./online_service_selection_step";
import SellingPriceStep from "./selling_price_step";
import NormalPriceStep from "./normal_price_step";
import SellingTimeStep from "./selling_time_step";
import SellingNumberStep from "./selling_number_step";
import HeaderTemplateSelectionStep from "./header_template_selection_step";
import HeaderSetupStep from "./header_setup_step";
import HeaderColorEditStep from "./header_color_edit_step";
import IntroductionSetupStep from "./introduction_setup_step";
import ContentSetupStep from "./content_setup_step";
import StaffSetupStep from "./staff_setup_step";
import ConfirmationStep from "./confirmation_step";
import FinalStep from "./final_step";

const SalesOnlineServiceCreationFlow = ({props}) => {
  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view with-function-bar">
          <GlobalProvider props={props}>
            <FlowController new_version={true}>
              <OnlineServiceSelectionStep />
              <SellingPriceStep />
              <NormalPriceStep />
              <SellingTimeStep />
              <SellingNumberStep />
              <HeaderTemplateSelectionStep />
              <HeaderSetupStep />
              <HeaderColorEditStep />
              <IntroductionSetupStep />
              <ContentSetupStep />
              <StaffSetupStep />
              <ConfirmationStep />
              <FinalStep />
            </FlowController>
          </GlobalProvider>
        </div>

        <div className="col-sm-6 px-0 hidden-xs preview-view"></div>
      </div>
    </div>
  )
}

export default SalesOnlineServiceCreationFlow
