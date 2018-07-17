"use strict";

import React from "react";
import "../payment_checkout";
import "./charge";

UI.define("SubscriptionModal", function() {
  return class SubscriptionModal extends React.Component {
    static planOrder = ["free", "basic", "premium"];

    constructor(props) {
      super(props);

      this.subscriptionPlan = this.props.plans[this.props.subscriptionPlanLevel];
      this.currentPlan = this.props.plans[this.props.currentPlanLevel];

      this.state = {
        upgradeImmediately: true
      };
    }

    renderTitle = () => {
      return this.subscriptionPlan.details.title;
    };

    renderContent = () => {
      if (this.props.currentPlanLevel === "free") {
        return (
          <div>
            <div>
              Subscribe Plan: {this.subscriptionPlan.details.title}
            </div>
            <div>
              Cost: {this.subscriptionPlan.costFormat}
            </div>
            <UI.PlanCharge
              formAuthenticityToken={this.props.formAuthenticityToken}
              paymentPath={this.props.paymentPath}
              stripeKey={this.props.stripeKey}
              email={this.props.email}
              processingMessage={this.props.processingMessage}
              locale={this.props.locale}
              plan={this.subscriptionPlan}
              />
          </div>
        );
      }
      else if (this.isUpgrade()) {
        return (
          <div>
            Subscribe Plan: {this.subscriptionPlan.details.title}
            You want to upgrade immediatelly or in next turn.
            <div>
              <input id="immediately"
                className="BTNselect"
                type="radio"
                checked={this.state.upgradeImmediately}
                name="immediately"
                onChange={this.onChangeUpgradePolicy}
                />
              <label htmlFor="immediately"><span>Immediately - 今すぐプランを変更する（今期分の返金不可）</span></label>
            </div>
            <div>
              <input id="later"
                className="BTNselect"
                type="radio"
                checked={!this.state.upgradeImmediately}
                name="later"
                onChange={this.onChangeUpgradePolicy}
                />
              <label htmlFor="later"><span>Later - 次の更新分からプランを変更する</span></label>
            </div>
            <UI.PlanCharge
              formAuthenticityToken={this.props.formAuthenticityToken}
              paymentPath={this.props.paymentPath}
              stripeKey={this.props.stripeKey}
              email={this.props.email}
              processingMessage={this.props.processingMessage}
              locale={this.props.locale}
              plan={this.subscriptionPlan}
              chargeImmediately={this.state.upgradeImmediately}
              />
          </div>
        );
      }
      else {
        return (
          <div>
            Subscribe Plan: {this.subscriptionPlan.details.title}
            You will downupgrade in next turn.
            <UI.PlanCharge
              formAuthenticityToken={this.props.formAuthenticityToken}
              paymentPath={this.props.paymentPath}
              stripeKey={this.props.stripeKey}
              email={this.props.email}
              processingMessage={this.props.processingMessage}
              locale={this.props.locale}
              plan={this.subscriptionPlan}
              chargeImmediately={false}
              />
          </div>
        );
      }
    };

    isUpgrade = () => {
      const subscriptionPlanIndex = SubscriptionModal.planOrder.indexOf(this.props.subscriptionPlanLevel);
      const currentPlanIndex = SubscriptionModal.planOrder.indexOf(this.props.currentPlanLevel);

      return subscriptionPlanIndex > currentPlanIndex;
    };

    onChangeUpgradePolicy = () => {
      this.setState(prevState => ({ upgradeImmediately: !prevState.upgradeImmediately }));
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
                  {this.renderContent()}
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
