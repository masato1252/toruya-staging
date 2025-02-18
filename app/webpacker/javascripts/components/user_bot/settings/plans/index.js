"use strict";

import React, { useEffect, useState } from "react";
import { StickyContainer, Sticky  } from 'react-sticky';
import Routes from 'js-routes.js'

import StripeCheckoutModal from "shared/stripe_checkout_modal";
import StripeChangeCardModal from "shared/stripe_change_card_modal";
import { TopNavigationBar } from "shared/components"
import SubscriptionModal from "components/management/plans/subscription_modal";
import SupportModal from "shared/support_modal";
import I18n from 'i18n-js/index.js.erb';

const Plans = ({props}) => {
  const freePlan = props.plans["free"];
  const basicPlan = props.plans["basic"];
  const premiumPlan = props.plans["premium"];

  const [selected_plan_level, seletePlan] = useState()
  const [selected_rank, seleteRank] = useState(props.default_upgrade_rank || props.current_rank)

  const isCurrentPlan = (planLevel) => {
    return props.current_plan_level === planLevel;
  };

  const selectedPlan = () => {
    return props.plans[selected_plan_level]
  };

  useEffect(() => {
    if (isUpgrade(props.default_upgrade_plan)) {
      onPay(props.default_upgrade_plan)
    }
  })

  const onPay = (planLevel) => {
    seletePlan(planLevel)

    $("#checkout-modal").modal("show");
  };

  const onSubscribe = (planLevel) => {
    seletePlan(planLevel)

    $("#subscription-modal").modal("show");
  };

  const subscriptionPlanIndex = (planLevel) => Plans.planOrder.indexOf(planLevel)
  const currentPlanIndex = () => Plans.planOrder.indexOf(props.current_plan_level)
  const isUpgrade = (planLevel) => subscriptionPlanIndex(planLevel) > currentPlanIndex()
  const handleFailure = (error) => {
    toastr.error(error.message)
  }

  const renderSaveOrPayButton = (planLevel) => {
    if (planLevel == "free") {
      return <></>
    }

    if (subscriptionPlanIndex(planLevel) == currentPlanIndex()) {
      return (
        <div
          className={`btn btn-yellow btn-small`}
          onClick={() => { $("#change-card-modal").modal("show"); }}>
          {I18n.t('plans.actions.change_card')}
        </div>
      )
    };

    if (isUpgrade(planLevel)) {
      return (
        <div
          className={`btn btn-yellow`}
          onClick={() => onPay(planLevel)} >
          {props.i18n.save}
        </div>
      )
    } else if (!isUpgrade(planLevel)) {
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

  const selectedPlanCustomerContext = (plan_level = "basic") => {
    return props.plans[plan_level].details["ranks"].find(plan_context => plan_context.rank === parseInt(selected_rank))
  }

  const customer_number_limit_info = (plan_level = "basic") => {
    return selectedPlanCustomerContext(plan_level)["max_customers_limit"]
  }

  const cost_info = (plan_level = "basic") => {
    return selectedPlanCustomerContext(plan_level)["costFormat"]
  }

  return (
    <StickyContainer className="plans">
      <Sticky>
        {({
          style,
        }) => (
          <div style={style}>
            <TopNavigationBar
              leading={<a href={Routes.lines_user_bot_settings_path(props.business_owner_id)}><i className="fa fa-angle-left fa-2x"></i></a>}
              title={props.i18n.plan_info.caption}
              sticky={true}
            />

            <div className="padding-around centerize customers-number-selection">
              <div>
                {props.i18n.how_many_customers_do_you_have}
              </div>
              <select name="plan_rank" onChange={(event) => seleteRank(event.target.value)} value={selected_rank}>
                {props.plans["basic"].details["ranks"].map(plan_context => {
                  const customer_number_contexts = props.plans["basic"].details["ranks"]

                  return (
                    <option value={plan_context.rank} key={plan_context.rank}>
                      {plan_context.max_customers_limit ? plan_context.max_customers_limit : `${customer_number_contexts[customer_number_contexts.length - 2].max_customers_limit}+`}
                    </option>
                  )
                })}
              </select>{I18n.t("common.person_unit")}
            </div>

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
                    {premiumPlan.selectable ? props.i18n.plan_info.current_plan : props.i18n.plan_info.unselectable}
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
            {header: I18n.t("plans.headers.customer_management")},
            "customer_number",
            "line_tab",
            "customer_notification",
            {header: I18n.t("plans.headers.reservation_management")},
            "reservation_restriction",
            {header: I18n.t("plans.headers.online_booking")},
            "booking_page_number",
            {header: I18n.t("plans.headers.online_service")},
            "get_more_friends",
            "free_lesson",
            "premium_lesson",
            "membership",
            "external_service",
            {header: I18n.t("plans.headers.sale_promotion")},
            "sale_page_number"
          ].map((labelName) => {
            if (typeof(labelName) === 'object') {
              return (
                <div className="table-row" key={labelName.header}>
                  <div className="col th header">{labelName.header}</div>
                </div>
              )
            }
            else if (labelName === "customer_number") {
              return (
                  <div className="table-row" key={labelName}>
                  <div className="col th">{props.plan_labels[labelName]}</div>
                  <div className={`col`}>
                    {freePlan.details[labelName]}
                  </div>
                  <div className={`col`}>
                    {customer_number_limit_info("basic")}{props.i18n.up_to_customers_limit}
                  </div>
                  <div className={`col`}>
                    {customer_number_limit_info("premium")}{props.i18n.up_to_customers_limit}
                  </div>
                </div>
              )
            }
            else {
              return (
                <div className="table-row" key={labelName}>
                  <div className="col th" dangerouslySetInnerHTML={{__html: props.plan_labels[labelName]}}></div>
                  <div className={`col`}>
                    <div dangerouslySetInnerHTML={{__html: freePlan.details[labelName]}}></div>
                  </div>
                  <div className={`col`}>
                    <div dangerouslySetInnerHTML={{__html: basicPlan.details[labelName]}}></div>
                  </div>
                  {premiumPlan?.details?.[labelName] && (
                    <div className={`col`}>
                      {premiumPlan.details[labelName]}
                    </div>
                  )}
                </div>
              )
            }
          })
        }
      </div>
      <div className="tfoot">
        <div className="table-row">
          <div className="col">
            {props.in_paid_plan && (
              <SupportModal
                props={props}
                trigger_btn={<button className="btn btn-orange">{props.i18n.unsubscribe}</button>}
                content={props.i18n.unsubscribe_modal_content}
                btn={props.i18n.unsubscribe_modal_button}
                reply={I18n.t("common.support_reply_html")}
                from_cancel={true}
              />
            )}
          </div>
          <div className={`col`}>
            <label>
              <div>{freePlan.details.period}</div>
              <div className="price-amount">{I18n.t("common.free_price")}</div>
            </label>
            {renderSaveOrPayButton("free")}
          </div>
          <div className={`col`}>
            <label>
              <div>{basicPlan.details.period}</div>
              <div className="price-amount">{cost_info("basic")}</div>
            </label>
            {renderSaveOrPayButton("basic")}
          </div>
          {premiumPlan?.details && (
            <div className={`col`}>
              <label>
                <div>{premiumPlan.details.period}</div>
                <div className="price-amount">{cost_info("premium")}</div>
              </label>
              {renderSaveOrPayButton("premium")}
            </div>
          ) }
        </div>
        {props.support_feature_flags.support_terms_and_privacy_display && (
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
        )}
      </div>
      <SubscriptionModal
        {...props}
        selectedPlan={selectedPlan()}
        rank={selected_rank}
      />
      <StripeCheckoutModal
        stripe_key={props.stripe_key}
        header="Trouya"
        plan_key={selectedPlan()?.key}
        rank={selected_rank}
        desc={selectedPlan()?.name}
        details_desc={`${basicPlan.details.period}: ${cost_info(selected_plan_level)}`}
        pay_btn={props.i18n.pay}
        payment_path={Routes.lines_user_bot_settings_payments_path(props.business_owner_id)}
        props={props}
        handleFailure={handleFailure}
      />
      <StripeChangeCardModal
        change_card_path={Routes.change_card_lines_user_bot_settings_payments_path(props.business_owner_id, {format: "json"})}
        stripe_key={props.stripe_key}
        business_owner_id={props.business_owner_id}
        header="Trouya"
        pay_btn={I18n.t('plans.actions.change_card')}
      />
    </StickyContainer>
  )
}

Plans.planOrder = ["free", "basic", "premium"]
export default Plans;
