import React from "react";
import I18n from 'i18n-js/index.js.erb';
import { useGlobalContext } from "./context/global_state";
import FlowStepIndicator from "./flow_step_indicator";
import { TopNavigationBar, CustomerSelectionList } from "shared/components"

const ManualAssignmentStep = ({next, step}) => {
  const { props, dispatch, selected_customer_ids } = useGlobalContext();

  const handleCustomerToggle = (customerId) => {
    const newSelectedCustomers = selected_customer_ids.includes(customerId)
      ? selected_customer_ids.filter(id => id !== customerId)
      : [...selected_customer_ids, customerId];

    dispatch({
      type: "UPDATE_SELECTED_CUSTOMERS",
      payload: newSelectedCustomers
    });
  };

  const handleNext = () => {
    if (selected_customer_ids.length > 0) {
      next();
    }
  };

  return (
    <div className="form settings-flow centerize manual-assignment-step with-top-bar">
      <TopNavigationBar
        leading={
          <a href={props.previous_path || Routes.lines_user_bot_broadcasts_path(props.business_owner_id)}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={I18n.t("user_bot.dashboards.broadcast_creation.manual_assignment")}
      />
      <FlowStepIndicator step={step} />
      <h3 className="header centerize">
        {I18n.t("user_bot.dashboards.broadcast_creation.manual_assignment")}
      </h3>
      <p className="margin-around desc">
        {I18n.t("user_bot.dashboards.broadcast_creation.manual_assignment_desc")}
      </p>

      <CustomerSelectionList
        candidateCustomers={props.candidate_customers}
        selectedCustomerIds={selected_customer_ids}
        onCustomerToggle={handleCustomerToggle}
        customerStatusType={props.customer_status_type}
      />

      <div className="action-block">
        <button
          onClick={handleNext}
          className="btn btn-yellow"
          disabled={selected_customer_ids.length === 0}
        >
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  );
};

export default ManualAssignmentStep;