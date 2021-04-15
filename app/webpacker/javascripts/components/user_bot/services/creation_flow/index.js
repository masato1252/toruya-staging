import React from "react";
import FlowController from "shared/flow_controller";
import { GlobalProvider, GlobalContext } from "./context/global_state"

import GoalSelectionStep from "./goal_selection_step"
import SolutionStep from "./solution_step"
import NameStep from "./name_step"
import CompanyInfoStep from "./company_info_step"
import EndtimeStep from "./endtime_step"
import UpsellStep from "./upsell_step"
import ConfirmationStep from "./confirmation_step"
import FinalStep from "./final_step"

const CreationFlow = ({props}) => {
  return (
    <GlobalProvider props={props}>
      <FlowController new_version={true}>
        <GoalSelectionStep />
        <SolutionStep />
        <NameStep />
        <CompanyInfoStep />
        <EndtimeStep />
        <UpsellStep />
        <ConfirmationStep />
        <FinalStep />
      </FlowController>
    </GlobalProvider>
  )
}

export default CreationFlow;
