"use strict";

import React from "react";
import FlowController from "shared/flow_controller";
import { GlobalProvider, GlobalContext } from "./context/global_state"
import BookingPageSelectionStep from "./booking_page_selection_step";
import HeaderSetupStep from "./header_setup_step";
import HeaderColorEditStep from "./header_color_edit_step";
import ContentSetupStep from "./content_setup_step";
import AuthorSetupStep from "./author_setup_step";
import FlowSetupStep from "./flow_setup_step";
import ConfirmationStep from "./confirmation_step";

const SalesBookingPageCreationFlow = ({props}) => {
  return (
    <GlobalProvider props={props}>
      <FlowController>
        { ({next, step}) => <BookingPageSelectionStep step={step} next={next} /> }
        { ({next, prev, step}) => <HeaderSetupStep step={step} next={next} prev={prev} /> }
        { ({next, prev, step}) => <HeaderColorEditStep step={step} next={next} prev={prev} /> }
        { ({next, prev, step}) => <ContentSetupStep step={step} next={next} prev={prev} /> }
        { ({next, prev, step}) => <AuthorSetupStep step={step} next={next} prev={prev} /> }
        { ({next, prev, step}) => <FlowSetupStep step={step} next={next} prev={prev} /> }
        { ({next, prev, step}) => <ConfirmationStep step={step} next={next} prev={prev} /> }
      </FlowController>
    </GlobalProvider>
  )
}

export default SalesBookingPageCreationFlow
