import React from "react";
import FlowController from "shared/flow_controller";
import { GlobalProvider } from "./context/global_state"

import NameStep from "./name_step"
import SolutionStep from "./solution_step"
import TagsStep from "./tags_step"
import NoteStep from "./note_step"
import StartTimeStep from "./start_time_step"
import ConfirmationStep from "./confirmation_step"

const CreationFlow = ({props}) => {
  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view">
          <GlobalProvider props={props}>
            <FlowController new_version={true}>
              <NameStep key="name_step" />
              <SolutionStep key="solution_step" />
              <TagsStep key="tags_step" />
              <NoteStep key="note_step" />
              <StartTimeStep />
              <ConfirmationStep key="confirmation_step" />
            </FlowController>
          </GlobalProvider>
        </div>

        <div className="col-sm-6 px-0 hidden-xs preview-view"></div>
      </div>
    </div>
  )
}

export default CreationFlow;
