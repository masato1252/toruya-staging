import React from "react";
import FlowController from "shared/flow_controller";
import { GlobalProvider, GlobalContext } from "./context/global_state"

import ServiceTypeSelectionStep from "./service_type_selection_step"
import ContentStep from "./content_step"
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
        { ({next, step}) => <ServiceTypeSelectionStep step={step} next={next} /> }
        { ({next, step, prev}) => <ContentStep step={step} next={next} prev={prev} /> }
        { ({next, step, prev}) => <NameStep step={step} next={next} prev={prev} /> }
        { ({next, step, prev}) => <CompanyInfoStep step={step} next={next} prev={prev} /> }
        { ({next, step, prev}) => <EndtimeStep step={step} next={next} prev={prev} /> }
        { ({next, step, prev}) => <UpsellStep step={step} next={next} prev={prev} /> }
        { ({next, step, prev, jump}) => <ConfirmationStep step={step} next={next} prev={prev} jump={jump} /> }
        { ({step}) => <FinalStep step={step} /> }
      </FlowController>
    </GlobalProvider>
  )
}

export default CreationFlow;
