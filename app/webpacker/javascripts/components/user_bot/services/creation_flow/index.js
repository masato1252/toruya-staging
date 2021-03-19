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
      <FlowController>
        { ({next, step}) => <GoalSelectionStep step={step} next={next} /> }
        { ({next, step}) => <SolutionStep step={step} next={next} /> }
        { ({next, step}) => <NameStep step={step} next={next} /> }
        { ({next, step}) => <CompanyInfoStep step={step} next={next} /> }
        { ({next, step}) => <EndtimeStep step={step} next={next} /> }
        { ({next, step}) => <UpsellStep step={step} next={next} /> }
        { ({next, step, jump}) => <ConfirmationStep step={step} next={next} jump={jump} /> }
        { ({step}) => <FinalStep step={step} /> }
      </FlowController>
    </GlobalProvider>
  )
}

export default CreationFlow;
