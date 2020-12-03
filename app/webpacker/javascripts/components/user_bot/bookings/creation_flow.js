"use strict";

import React from "react";
import FlowController from "shared/flow_controller";
import { GlobalProvider, GlobalContext } from "context/user_bots/bookings/global_state"

import ShopSelectionStep from "./shop_selection_step";
import MenuSelectionStep from "./menu_selection_step";
import PriceSetupStep from "./price_setup_step";
import NoteSetupStep from "./note_setup_step";
import ConfirmationStep from "./confirmation_step";
import FinalStep from "./final_step";

const CreationFlow = ({props}) => {
  return (
    <GlobalProvider props={props}>
      <FlowController>
        { ({next, step}) => <ShopSelectionStep next={next} step={step} /> }
        { ({next, jump, step}) => <MenuSelectionStep next={next} jump={jump} step={step} /> }
        { ({next, step}) => <PriceSetupStep next={next} step={step} /> }
        { ({next, step}) => <NoteSetupStep next={next} step={step} /> }
        { ({next, jump, step}) => <ConfirmationStep next={next} jump={jump} step={step} /> }
        { ({step}) => <FinalStep step={step} /> }
      </FlowController>
    </GlobalProvider>
  )

}

export default CreationFlow;
