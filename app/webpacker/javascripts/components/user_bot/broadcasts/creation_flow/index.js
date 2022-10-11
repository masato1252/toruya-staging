import React from "react";

import FlowController from "shared/flow_controller";
import { GlobalProvider } from "./context/global_state"

import FiltersSelectionStep from "./filters_selection_step"
import FroductSelectionStep from "./product_selection_step"
import ContentSetupStep from "./content_setup_step"
import ScheduleSetupStep from "./schedule_setup_step"

const CreationFlow = ({props}) => {
  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0">
          <GlobalProvider props={props}>
            <FlowController new_version={true}>
              <FiltersSelectionStep />
              <FroductSelectionStep />
              <ContentSetupStep />
              <ScheduleSetupStep />
            </FlowController>
          </GlobalProvider>
        </div>

        <div className="col-sm-6 px-0 hidden-xs"></div>
      </div>
    </div>
  )
}

export default CreationFlow;
