import React from "react";

import FlowController from "shared/flow_controller";
import { GlobalProvider } from "./context/global_state"

import FiltersSelectionStep from "./filters_selection_step"
import ProductSelectionStep from "./product_selection_step"
import ContentSetupStep from "./content_setup_step"
import ScheduleSetupStep from "./schedule_setup_step"
import ManualAssignmentStep from "./manual_assignment_step"

const CreationFlow = ({props}) => {
  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view">
          {props.broadcast.query_type === "manual_assignment" ? (
            <GlobalProvider props={props}>
              <FlowController new_version={true}>
                <ManualAssignmentStep />
                <ContentSetupStep />
                <ScheduleSetupStep />
              </FlowController>
            </GlobalProvider>
          ) : (
            <GlobalProvider props={props}>
              <FlowController new_version={true}>
                <FiltersSelectionStep />
                <ProductSelectionStep />
                <ContentSetupStep />
                <ScheduleSetupStep />
              </FlowController>
            </GlobalProvider>
          )}
        </div>

        <div className="col-sm-6 px-0 hidden-xs preview-view"></div>
      </div>
    </div>
  )
}

export default CreationFlow;
