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
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view with-function-bar">
          <GlobalProvider props={props}>
            <FlowController new_version={true}>
              <ShopSelectionStep />
              <MenuSelectionStep />
              <PriceSetupStep />
              <NoteSetupStep />
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

export default CreationFlow;
