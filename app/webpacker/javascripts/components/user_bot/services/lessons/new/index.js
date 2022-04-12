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
    <GlobalProvider props={props}>
      <FlowController new_version={true}>
        <NameStep />
        <SolutionStep />
        <NoteStep />
        <StartTimeStep />
        <ConfirmationStep />
      </FlowController>
    </GlobalProvider>
  )
}

export default LessonNew;
