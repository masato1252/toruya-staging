import React from "react";
import FlowController from "shared/flow_controller";
import { GlobalProvider, GlobalContext } from "./context/global_state"

import GoalSelectionStep from "./goal_selection_step"
import SolutionStep from "./solution_step"
import NameStep from "./name_step"
import LineMessageStep from "./line_message_step"
import CompanyInfoStep from "./company_info_step"
import EndtimeStep from "./endtime_step"
import UpsellStep from "./upsell_step"
import ConfirmationStep from "./confirmation_step"
import FinalStep from "./final_step"

// Course goal's final step is EndtimeStep
// Membership goal's final step is CompanyInfoStep
const CreationFlow = ({props}) => {
  return (
    <GlobalProvider props={props}>
      <FlowController new_version={true}>
        <GoalSelectionStep key="goal_selection_step" />
        <SolutionStep key="solution_step" />
        <NameStep key="name_step" />
        <LineMessageStep key="line_message_step" />
        <CompanyInfoStep key="company_step" />
        <EndtimeStep key="endtime_step" />
        <UpsellStep key="upsell_step" />
        <ConfirmationStep key="confirmation_step" />
        <FinalStep />
      </FlowController>
    </GlobalProvider>
  )
}

export default CreationFlow;
