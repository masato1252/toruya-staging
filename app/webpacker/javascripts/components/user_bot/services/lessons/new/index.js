import React from "react";
import FlowController from "shared/flow_controller";
import { GlobalProvider } from "./context/global_state"

import NameStep from "./name_step"
import SolutionStep from "./solution_step"
import NoteStep from "./note_step"
import StartTimeStep from "./start_time_step"
import ConfirmationStep from "./confirmation_step"

const LessonNew = ({props}) => {
  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0">
          <GlobalProvider props={props}>
            <FlowController new_version={true}>
              <NameStep />
              <SolutionStep />
              <NoteStep />
              <StartTimeStep />
              <ConfirmationStep />
            </FlowController>
          </GlobalProvider>
        </div>

        <div className="col-sm-6 px-0 hidden-xs"></div>
      </div>
    </div>
  )
}

export default LessonNew;
