"use strict";

import React from "react";
import FlowController from "shared/flow_controller";
import { GlobalProvider, GlobalContext } from "./context/global_state"
import BookingPageSelectionStep from "./booking_page_selection_step";
import HeaderTemplateSelectionStep from "./header_template_selection_step";
import HeaderSetupStep from "./header_setup_step";
import HeaderColorEditStep from "./header_color_edit_step";
import ContentSetupStep from "./content_setup_step";
import StaffSetupStep from "./staff_setup_step";
import FlowSetupStep from "./flow_setup_step";
import ConfirmationStep from "./confirmation_step";
import FinalStep from "./final_step";

const SalesBookingPageCreationFlow = ({props}) => {
  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view">
          <GlobalProvider props={props}>
            <FlowController new_version={true}>
              <BookingPageSelectionStep key="booking_page_selection_step" /> 
              <HeaderTemplateSelectionStep key="header_template_selection_step" />
              <HeaderSetupStep key="header_setup_step" />
              <HeaderColorEditStep key="header_color_edit_step" />
              <ContentSetupStep key="content_setup_step" />
              <StaffSetupStep key="staff_setup_step" />
              <FlowSetupStep key="flow_setup_step" />
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

export default SalesBookingPageCreationFlow
