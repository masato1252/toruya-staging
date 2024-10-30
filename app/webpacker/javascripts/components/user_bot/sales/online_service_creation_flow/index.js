"use strict";

import React from "react";
import FlowController from "shared/flow_controller";
import { GlobalProvider } from "./context/global_state"
import OnlineServiceSelectionStep from "./online_service_selection_step";
import SellingPriceStep from "./selling_price_step";
import SellingTimeStep from "./selling_time_step";
import SellingNumberStep from "./selling_number_step";
import HeaderTemplateSelectionStep from "./header_template_selection_step";
import HeaderSetupStep from "./header_setup_step";
import HeaderColorEditStep from "./header_color_edit_step";
import ContentSetupStep from "./content_setup_step";
import StaffSetupStep from "./staff_setup_step";
import ConfirmationStep from "./confirmation_step";
import FinalStep from "./final_step";

const SalesOnlineServiceCreationFlow = ({props}) => {
  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view">
          <GlobalProvider props={props}>
            <FlowController new_version={true}>
              <OnlineServiceSelectionStep key="online_service_selection_step" />
              <SellingPriceStep key="selling_price_step" />
              <SellingTimeStep key="selling_time_step" />
              <SellingNumberStep key="selling_number_step" />
              <HeaderTemplateSelectionStep key="header_template_selection_step" />
              <HeaderSetupStep key="header_setup_step" />
              <HeaderColorEditStep key="header_color_edit_step" />
              <ContentSetupStep key="content_setup_step" />
              <StaffSetupStep key="staff_setup_step" />
              <ConfirmationStep key="confirmation_step" />
              <FinalStep key="final_step" />
            </FlowController>
          </GlobalProvider>
        </div>

        <div className="col-sm-6 px-0 hidden-xs preview-view"></div>
      </div>
    </div>
  )
}

export default SalesOnlineServiceCreationFlow
