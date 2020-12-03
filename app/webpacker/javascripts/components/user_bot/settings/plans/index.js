"use strict";

import React, { useState } from "react";
import { StickyContainer, Sticky  } from 'react-sticky';

import StripeCheckoutModal from "shared/stripe_checkout_modal";
import { TopNavigationBar } from "shared/components"
import SubscriptionModal from "components/management/plans/subscription_modal";

const Plans = ({props}) => {
  const freePlan = props.plans["free"];
  const basicPlan = props.plans["basic"];
  const premiumPlan = props.plans["premium"];

  const [selected_plan_level, seletePlan] = useState()

  const isCurrentPlan = (planLevel) => {
    return props.current_plan_level === planLevel;
  };

  const selectedPlan = () => {
    return props.plans[selected_plan_level]
  };

  const onPay = (planLevel) => {
    seletePlan(planLevel)

    $("#checkout-modal").modal("show");
  };

  const onSubscribe = (planLevel) => {
    seletePlan(planLevel)

    $("#subscription-modal").modal("show");
  };

  const renderSaveOrPayButton = (planLevel) => {
    const subscriptionPlanIndex = Plans.planOrder.indexOf(planLevel);
    const currentPlanIndex = Plans.planOrder.indexOf(props.current_plan_level);
    const isUpgrade = subscriptionPlanIndex > currentPlanIndex;

    if (subscriptionPlanIndex == currentPlanIndex) {
      return (
        <div className={`btn btn-yellow disabled`} >
          {props.i18n.save}
        </div>
      )
    };

    if (isUpgrade) {
      return (
        <div
          className={`btn btn-yellow`}
          onClick={() => onPay(planLevel)} >
          {props.i18n.save}
        </div>
      )
    } else if (!isUpgrade) {
      // downgrade
      return (
        <div
          className={`btn btn-yellow`}
          onClick={() => onSubscribe(planLevel)} >
          {props.i18n.save}
        </div>
      )
    }
  };

  return (
    <StickyContainer className="plans">
      <Sticky>
        {({
          style,
        }) => (
          <div style={style}>
            <TopNavigationBar
              leading={<a href={Routes.lines_user_bot_settings_path()}><i className="fa fa-angle-left fa-2x"></i></a>}
              title={props.i18n.plan_info.caption}
              sticky={true}
            />
            <div className="thead">
              <div className="col"></div>
              <div className={`col free ${isCurrentPlan("free") && "current"}`}>
                {freePlan.details.title}
                <div className={`plan-column ${isCurrentPlan("free") && "current"}`}>
                  <i className="fa fa-check-circle" aria-hidden="true" />
                  <span>
                    {basicPlan.selectable ? props.i18n.plan_info.current_plan : props.i18n.plan_info.unselectable}
                  </span>
                </div>
              </div>
              <div className={`col basic ${isCurrentPlan("basic") && "current"}`}>
                {basicPlan.details.title}
                <div className={`plan-column ${isCurrentPlan("basic") && "current"}`}>
                  <i className="fa fa-check-circle" aria-hidden="true" />
                  <span>
                    {basicPlan.selectable ? props.i18n.plan_info.current_plan : props.i18n.plan_info.unselectable}
                  </span>
                </div>
              </div>
              <div className={`col premium ${isCurrentPlan("premium") && "current"}`}>
                {premiumPlan.details.title}
                <div className={`plan-column ${isCurrentPlan("premium") && "current"}`}>
                  <i className="fa fa-check-circle" aria-hidden="true" />
                  <span>
                    {basicPlan.selectable ? props.i18n.plan_info.current_plan : props.i18n.plan_info.unselectable}
                  </span>
                </div>
              </div>
            </div>
          </div>
        )}
      </Sticky>
      <div className="tbody">
        {
          [
            "shop_can_set",
            "staff_in_charge",,
            "max_customer_per_reservation",
            "reservation_restriction",
            "private_schedule",
            "customer_info",
            "customer_group_limit",
            "customer_filter",
            "print_address",
            "add_staff"
          ].map((labelName) => {
            return (
              <div className="table-row" key={labelName}>
                <div className="col th">{props.plan_labels[labelName]}</div>
                <div className={`col`}>
                  {freePlan.details[labelName]}
                </div>
                <div className={`col`}>
                  {basicPlan.details[labelName]}
                </div>
                <div className={`col`}>
                  {premiumPlan.details[labelName]}
                </div>
              </div>
            )
          })
        }
      </div>
      <div className="tfoot">
        <div className="table-row">
          <div className="col"></div>
          <div className={`col`}>
            <label>
              <div>{freePlan.details.period}</div>
              <div className="price-amount">無料</div>
            </label>
            {renderSaveOrPayButton("free")}
          </div>
          <div className={`col`}>
            <label>
              <div>{basicPlan.details.period}</div>
              <div className="price-amount">{basicPlan.costFormat}</div>
            </label>
            {renderSaveOrPayButton("basic")}
          </div>
          <div className={`col`}>
            <label>
              <div>{premiumPlan.details.period}</div>
              <div className="price-amount">{premiumPlan.costFormat}</div>
            </label>
            {renderSaveOrPayButton("premium")}
          </div>
        </div>
        <div className="table-row">
          <div className="col">
            <div className="privacy-and-term">
              全てのプランにおいて、Toruyaの
              <a href='https://toruya.com/privacy/' target='_blank'>プライバシーポリシー</a>
              と
              <a href='https://toruya.com/terms/' target='_blank'>利用規約</a>
              が適応されます。
            </div>
          </div>
        </div>
      </div>
      <SubscriptionModal
        {...props}
        selectedPlan={selectedPlan()}
      />
      <StripeCheckoutModal
        stripe_key={props.stripe_key}
        header="Trouya"
        plan_key={selectedPlan()?.key}
        desc={selectedPlan()?.name}
        details_desc={`${premiumPlan.details.period}: ${selectedPlan()?.costFormat}`}
        pay_btn={props.i18n.pay}
        payment_path={Routes.lines_user_bot_settings_payments_path()}
        props={props}
      />
    </StickyContainer>
  )
}

Plans.planOrder = ["free", "basic", "premium"]
export default Plans;
