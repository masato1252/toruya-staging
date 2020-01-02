"use strict";

import React from "react";
import SubscriptionModal from "./subscription_modal";
import ChargeFailedModal from "./charge_failed";
import PlanCharge from "./charge";

class Plans extends React.Component {
  static planOrder = ["free", "basic", "premium"];

  constructor(props) {
    super(props);

    this.freePlan = this.props.plans["free"];
    this.basicPlan = this.props.plans["basic"];
    this.premiumPlan = this.props.plans["premium"];

    this.state = {
      subscriptionPlanLevel: null,
      selectedPlanLevel: this.props.defaultUpgradePlan,
      upgradeImmediately: true,
      shopFeeConfirmation: false
    }
  };

  isCurrentPlan = (planLevel) => {
    return this.props.currentPlanLevel === planLevel;
  };

  isSelectedPlan = (planLevel) => {
    return this.state.selectedPlanLevel === planLevel;
  };

  selectedPlan = () => {
    return this.props.plans[this.state.selectedPlanLevel]
  };

  onDataChange = (event) => {
    let stateName = event.target.dataset.name;
    let stateValue = event.target.dataset.value || event.target.value;

    this.setState({[stateName]: stateValue})
  };

  onChangeUpgradePolicy = () => {
    this.setState(prevState => ({ upgradeImmediately: !prevState.upgradeImmediately }));
  };

  toggleShopFeeConfirmation = () => {
    this.setState(prevState => ({ shopFeeConfirmation: !prevState.shopFeeConfirmation }));
  };

  onSubscribe = (event) => {
    event.preventDefault();

    $("#subscription-modal").modal("show");
  };

  isUpgrade = () => {
    const subscriptionPlanIndex = Plans.planOrder.indexOf(this.state.selectedPlanLevel);
    const currentPlanIndex = Plans.planOrder.indexOf(this.props.currentPlanLevel);

    return subscriptionPlanIndex > currentPlanIndex;
  };

  renderUpgradeOptions = () => {
    if (!this.state.selectedPlanLevel) { return; }

    if (this.props.chargeDirectly) {
      return;
    } else if (this.isUpgrade()) {
      return (
        <div className="upgrade-area">
          <div className="caption">
            <div className="upgrade-label">{this.props.i18n.upgradeCaptionTitle}</div>
            <div className="detial">{this.props.i18n.upgradeCaptionDesc}</div>
          </div>
          <label className="upgrade-options">
            <div className="upgrade-label">
              <input id="immediately"
                type="radio"
                checked={this.state.upgradeImmediately}
                name="immediately"
                onChange={this.onChangeUpgradePolicy}
                />
              <span>{this.props.i18n.upgradeImmediately}</span>
            </div>
            <div className="desc">{this.props.i18n.upgradeImmediatelyDesc}</div>
          </label>
          <label className="upgrade-options">
            <div className="upgrade-label">
              <input id="later"
                type="radio"
                checked={!this.state.upgradeImmediately}
                name="immediately"
                onChange={this.onChangeUpgradePolicy}
                />
              <span>{this.props.i18n.upgradeLater}</span>
            </div>
            <div className="desc">{this.props.i18n.upgradeLaterDesc}</div>
          </label>
        </div>
      )
    }
  };

  renderPremiumUpgradeReminder = () => {
    if (this.isSelectedPlan("premium") && this.props.isExceededPremiumBaseShops) {
      return (
        <div className="shop-fee-confirmation-area">
          <div className="caption">
            <div className="upgrade-label">{this.props.i18n.shopFeeCaptionTitle}</div>
            <div className="detial">{this.props.i18n.shopFeeCaptionDesc}</div>
          </div>
          <label className="confirmation-option">
            <div className="shop-fee-label">
              <input
                type="checkbox"
                checked={this.state.shopFeeConfirmation}
                onChange={this.toggleShopFeeConfirmation}
                />
              <span>{this.props.i18n.shopFeeConfirmation}</span>
            </div>
          </label>
        </div>
      )
    }
  };

  renderPremiumUpgradeStaffReminder = () => {
    if (this.isSelectedPlan("premium") && this.props.isExceededStaff) {
      return (
        <div className="extra-staff-area">
          <div className="caption">
            <div className="upgrade-label">{this.props.i18n.extraStaffCaptionTitle}</div>
            <div className="detial">{this.props.i18n.extraStaffCaptionDesc}</div>
          </div>
        </div>
      )
    }
  };

  isUserConfirmShopFee = () => {
    return !this.isSelectedPlan("premium") || !this.props.isExceededPremiumBaseShops || this.state.shopFeeConfirmation;
  };

  renderSaveOrPayButton = () => {
    if (!this.state.selectedPlanLevel || !this.isUserConfirmShopFee()) {
      return (
        <div
          className={`btn btn-yellow disabled`}>
          {this.props.i18n.saveAndPay}
        </div>
      )
    }

    if (this.isUpgrade()) {
      return (
        <PlanCharge
          {...this.props}
          chargeImmediately={this.state.upgradeImmediately}
          plan={this.selectedPlan()}
        />
      )
    } else if (!this.isUpgrade()) {
      // downgrade
      return (
        <div
          className={`btn btn-yellow`}
          onClick={this.onSubscribe} >
          {this.props.i18n.save}
        </div>
      )
    }
  };

  render() {
    return (
      <div className="plans">
        <table>
          <thead>
            <tr>
              <th className="invisible"></th>
              <th className={`free ${this.isCurrentPlan("free") && "current"} plan-column ${this.isCurrentPlan("free") && "current"}`}>
                {this.freePlan.details.title}
              </th>
              <th className={`basic ${this.isCurrentPlan("basic") && "current"} plan-column ${this.isCurrentPlan("basic") && "current"}`}>
                {this.basicPlan.details.title}
              </th>
              <th className={`premium ${this.isCurrentPlan("premium") && "current"}`}>
                {this.premiumPlan.details.title}
              </th>
            </tr>
            <tr className="price-row">
              <th className="invisible"></th>
              <td className={`${this.isSelectedPlan("free") && "selected-plan"}`}>
                <label>
                  <div>{this.freePlan.details.period}</div>
                  <div className="price-amount">無料</div>
                  <div className={`plan-column ${this.isCurrentPlan("free") && "current"}`}>
                    <i className="fa fa-check-circle" aria-hidden="true" />
                    <span>
                      {this.freePlan.selectable ? this.props.i18n.currentPlan : this.props.i18n.unselectable}
                    </span>
                  </div>
                  <input
                    type="radio"
                    className={`select-plan ${this.isCurrentPlan("free") && "current-plan"}`}
                    data-name="selectedPlanLevel"
                    data-value="free"
                    checked={this.state.selectedPlanLevel === "free"}
                    onChange={this.onDataChange}
                    disabled={this.isCurrentPlan("free")}
                    />
                </label>
              </td>
              <td className={`${this.isSelectedPlan("basic") && "selected-plan"}`}>
                <label>
                  <div>{this.basicPlan.details.period}</div>
                  <div className="price-amount">{this.basicPlan.costFormat}</div>
                  <div className={`plan-column ${this.isCurrentPlan("basic") && "current"}`}>
                    <i className="fa fa-check-circle" aria-hidden="true" />
                    <span>
                      {this.basicPlan.selectable ? this.props.i18n.currentPlan : this.props.i18n.unselectable}
                    </span>
                  </div>
                  <input
                    type="radio"
                    className={`select-plan ${this.isCurrentPlan("basic") && "current-plan"}`}
                    data-name="selectedPlanLevel"
                    data-value="basic"
                    checked={this.state.selectedPlanLevel === "basic"}
                    onChange={this.onDataChange}
                    disabled={this.isCurrentPlan("basic")}
                    />
                </label>
              </td>
              <td className={`${this.isSelectedPlan("premium") && "selected-plan"}`}>
                <label>
                  <div>{this.premiumPlan.details.period}</div>
                  <div className="price-amount">{this.premiumPlan.costFormat}</div>
                  <div className={`plan-column ${this.isCurrentPlan("premium") && "current"}`}>
                    <i className="fa fa-check-circle" aria-hidden="true" />
                    <span>
                      {this.premiumPlan.selectable ? this.props.i18n.currentPlan : this.props.i18n.unselectable}
                    </span>
                  </div>
                  <input
                    type="radio"
                    className={`select-plan ${this.isCurrentPlan("premium") && "current-plan"}`}
                    data-name="selectedPlanLevel"
                    data-value="premium"
                    checked={this.state.selectedPlanLevel === "premium"}
                    disabled={this.isCurrentPlan("premium")}
                    onChange={this.onDataChange}
                    />
                </label>
              </td>
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
                    <td className={`${this.isSelectedPlan("free") && "selected-plan"}`}>
                      {this.freePlan.details[labelName]}
                    </td>
                    <td className={`${this.isSelectedPlan("basic") && "selected-plan"}`}>
                      {this.basicPlan.details[labelName]}
                    </td>
                    <td className={`${this.isSelectedPlan("premium") && "selected-plan"}`}>
                    {this.premiumPlan.details[labelName]}
                    </td>
                  </tr>
                )
              })
            }
          </tbody>
        </table>
        {this.renderUpgradeOptions()}
        {this.renderPremiumUpgradeStaffReminder()}
        {this.renderPremiumUpgradeReminder()}
        <div className="privacy-and-term">
          全てのプランにおいて、Toruyaの
            <a href='https://toruya.com/privacy/' target='_blank'>プライバシーポリシー</a>
            と
            <a href='https://toruya.com/terms/' target='_blank'>利用規約</a>
            が適応されます。
        </div>
        <div className="actions">
          <a href={this.props.paymentsPath}
            className={`btn btn-tarco`} >
            {this.props.i18n.cancel}
          </a>
          {this.renderSaveOrPayButton()}
        </div>
        {
          this.state.selectedPlanLevel && (
            <SubscriptionModal
              {...this.props}
              selectedPlan={this.selectedPlan()}
              />
          )
        }
        <ChargeFailedModal
          {...this.props}
        />
      </div>
    )
  }
};

export default Plans;
