"use strict";

import React from "react";
import "./subscription_modal";

UI.define("Plans", function() {
  return class Plans extends React.Component {
    constructor(props) {
      super(props);

      this.freePlan = this.props.plans["free"];
      this.basicPlan = this.props.plans["basic"];
      this.premiumPlan = this.props.plans["premium"];

      this.state = {
        subscriptionPlanLevel: null
      }
    };

    isCurrentPlan = (planLevel) => {
      return this.props.currentPlanLevel === planLevel;
    };

    onSubscribe = (event) => {
      event.preventDefault();

      this.setState({subscriptionPlanLevel: event.target.dataset.planLevel}, () => {
        $("#subscription-modal").modal("show");
      })
    };

    render() {
      return (
        <div>
          <table className="plans">
            <thead>
              <tr>
                <th className="invisible"></th>
                <th className={`invisible ${this.isCurrentPlan("free") && "current"}`}>
                  Current Plan
                </th>
                <th className={`invisible ${this.isCurrentPlan("basic") && "current"}`}>
                  Current Plan
                </th>
                <th className={`invisible ${this.isCurrentPlan("premium") && "current"}`}>
                  Current Plan
                </th>
              </tr>
              <tr>
                <th className="invisible"></th>
                <th className={`free ${this.isCurrentPlan("free") && "current"}`}>
                  {this.freePlan.details.title}
                </th>
                <th className={`basic ${this.isCurrentPlan("basic") && "current"}`}>
                  {this.basicPlan.details.title}
                </th>
                <th className={`premium ${this.isCurrentPlan("premium") && "current"}`}>
                  {this.premiumPlan.details.title}
                </th>
              </tr>
              <tr>
                <th className="invisible"></th>
                <td>無料</td>
                <td>{this.basicPlan.costFormat}／月</td>
                <td>{this.premiumPlan.costFormat}／月</td>
              </tr>
            </thead>
            <tbody>
              {
                [
                  "shopCanSet",
                  "staffInCharge",,
                  "maxCustomerPerReservation",
                  "reservationRestriction",
                  "privateSchedule",
                  "customerInfo",
                  "customerGroupLimit",
                  "customerFilter",
                  "printAddress",
                  "addStaff"
                ].map((labelName) => {
                  return (
                    <tr key={labelName}>
                      <th>{this.props.planLabels[labelName]}</th>
                      <td>{this.freePlan.details[labelName]}</td>
                      <td>{this.basicPlan.details[labelName]}</td>
                      <td>{this.premiumPlan.details[labelName]}</td>
                    </tr>
                  )
                })
              }
              <tr>
                <th>
                </th>
                <td>
                  {
                    this.props.currentPlanLevel !== "free" && (
                      <button
                        className="btn btn-orange"
                        rel="nofollow"
                        data-plan-level="free"
                        onClick={this.onSubscribe}
                        >
                        Downgrade
                      </button>
                    )
                  }
                </td>
                <td>
                  {
                    this.props.currentPlanLevel !== "basic" && (
                      <button
                        className="btn btn-orange"
                        rel="nofollow"
                        data-plan-level="basic"
                        onClick={this.onSubscribe}
                        >
                        Subscribe
                      </button>
                    )
                  }
                </td>
                <td>
                  {
                    this.props.currentPlanLevel !== "premium" && (
                      <button
                        className="btn btn-orange"
                        rel="nofollow"
                        data-plan-level="premium"
                        onClick={this.onSubscribe}
                        >
                        Subscribe
                      </button>
                    )
                  }
                </td>
              </tr>
            </tbody>
          </table>
          {
            this.state.subscriptionPlanLevel && (
              <UI.SubscriptionModal
                {...this.props}
                subscriptionPlanLevel={this.state.subscriptionPlanLevel}
                />
            )
          }
        </div>
      )
    }
  };
});

export default UI.Plans;
