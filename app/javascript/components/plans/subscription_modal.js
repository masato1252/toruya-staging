"use strict";

import React from "react";

UI.define("SubscriptionModal", function() {
  return class SubscriptionModal extends React.Component {
    static planOrder = ["free", "basic", "premium"];

    constructor(props) {
      super(props);

      this.subscriptionPlan = this.props.plans[this.props.subscriptionPlanLevel];
      this.currentPlan = this.props.plans[this.props.currentPlanLevel];
    }

    renderTitle = () => {
      return this.subscriptionPlan.details.title;
    };

    renderContent = () => {
      if (this.props.isFirstTimeSubscribe) {
        return (
          <div>
            <div>
              Subscribe Plan: {this.subscriptionPlan.details.title}
            </div>
            <div>
              Cost: {this.subscriptionPlan.costFormat}
            </div>
          </div>
        );
      }
      else if (this.isUpgrade()) {
        <div>
          Subscribe Plan: {this.subscriptionPlan.details.title}
          You want to upgrade immediatelly or in next turn.
          <div>
            <input id="immediately"
              className="BTNselect"
              type="radio"
              defaultValue={true}
              name="immediately"
              />
            <label htmlFor="immediately"><span>{this.props.staffAccountStaffLevelLabel}</span></label>
          </div>
          <div>
            <input id="later"
              className="BTNselect"
              type="radio"
              defaultValue={false}
              name="immediately"
              />
            <label htmlFor="later"><span>{this.props.staffAccountManagerLevelLabel}</span></label>
          </div>
        </div>
      }
      else {

      }
    };

    isUpgrade = () => {
      const subscriptionPlanIndex = planOrder.indexOf(this.props.subscriptionPlanLevel);
      const currentPlanIndex = planOrder.indexOf(this.props.currentPlanLevel);

      return subscriptionPlanIndex > currentPlanIndex;
    };

    render() {
      return (
        <div className="modal fade" id="subscription-modal" tabIndex="-1" role="dialog">
          <div className="modal-dialog" role="document">
            <div className="modal-content">
              <div className="modal-header">
                <button type="button" className="close" data-dismiss="modal" aria-label="Close">
                  <span aria-hidden="true">×</span>
                </button>
                <h4 className="modal-title" id="myModalLabel">
                  {this.renderTitle()} Plan
                </h4>
                </div>
                <div className="modal-body">
                </div>
                <div className="modal-footer">
                  {this.props.actions}
                </div>
              </div>
            </div>
          </div>
      );
    }
  };
});

export default UI.SubscriptionModal;
