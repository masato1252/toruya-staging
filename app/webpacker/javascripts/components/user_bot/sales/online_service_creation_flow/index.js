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
  )
}

export default SalesOnlineServiceCreationFlow
