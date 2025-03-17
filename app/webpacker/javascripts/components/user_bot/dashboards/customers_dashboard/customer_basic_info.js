"use strict"

import React from "react";
import { useHistory } from "react-router-dom";

import { useGlobalContext } from "context/user_bots/customers_dashboard/global_state";
import { NotificationMessages } from "shared/components"
import { CustomerTopActions } from "./top_actions";
import { CustomerServices } from "user_bot/api";

const CustomerTopRightAction = () => {
  const { selected_customer, props, dispatch } = useGlobalContext()

  if (!selected_customer?.id) { return <span></span>; }

  switch(props.from) {
    case "reservation":
      return <a className="btn btn-yellow" href={Routes.form_lines_user_bot_shop_reservations_path({business_owner_id: props.business_owner_id, shop_id: props.shop.id, reservation_id: props.reservation_id, from: "adding_customer", customer_id: selected_customer.id})}>
          <i className="fa fa-user-plus"></i>{props.i18n.decide_customer}
        </a>
    default:
      return <></>
  }
}

const CustomerBasicInfo = () => {
  const { dispatch, selected_customer, notification_messages, props } = useGlobalContext()
  let history = useHistory();

  return (
    <div>
      <NotificationMessages notification_messages={notification_messages} dispatch={dispatch} />
      <div className="customer-basic-info">
        {props.from_options.service_customer_show != props.from && (
          <CustomerTopActions
            leading={
              <a onClick={() => {
                if (props.previous_path) {
                  window.location = props.previous_path
                }
                else {
                  dispatch({ type: "CHANGE_VIEW", payload: { view: "customers_list" } })
                  dispatch({ type: "SELECT_CUSTOMER", payload: { customer: {} } })
                  history.goBack()
                }
              }} >
                <i className="fa fa-angle-left fa-2x"></i>
              </a>
            }
            tail={<CustomerTopRightAction />}
          />
        )}
        <div className="customer-data">
          {props.support_feature_flags.support_advance_customer_info && (
            <div className="group-rank">
              {
                selected_customer.groupName ? (
                <div>{selected_customer.groupName}</div>
              ) : (
                <div className="field-error-border">{props.i18n.group_blank_option}</div>
              )
            }

            {
              selected_customer.rank && (
                <div className={selected_customer.rank.key}>{selected_customer.rank.name}</div>
              )
            }
          </div>
          )}
          <div className="names">
            {props.support_feature_flags.support_phonetic_name && (
              <div className="phonetic-name">
                <span>
                {selected_customer.phoneticLastName}
              </span>
              <span>
                {selected_customer.phoneticFirstName}
              </span>
              </div>
            )}

            <div className="name">
              <span>
                {selected_customer.lastName}
              </span>
              <span>
                {selected_customer.firstName}
              </span>
            </div>
          </div>
          <div className="notifiers">
            <a
              data-id="customer-reminder-toggler"
              onClick={() => {
                CustomerServices.toggle_reminder_permission({ business_owner_id: props.business_owner_id, customer_id: selected_customer.id })

                const tooltip = $("[data-id='customer-reminder-toggler']").tooltip({
                  trigger: "manual",
                  title: `${props.i18n.reminder_changed_message} ${selected_customer.reminderPermission ? "OFF" : "ON"}`
                })

                tooltip.tooltip("show")

                setTimeout(function() {
                  tooltip.tooltip("destroy")
                }, 2000);

                dispatch({
                  type: "UPDATE_CUSTOMER_REMINDER_PERMISSION",
                  payload: {
                    reminderPermission: !selected_customer.reminderPermission
                  }
                })
            }}>
              <i className={`customer-reminder-permission fa fa-bell  ${selected_customer.reminderPermission ? "reminder-on" : ""}`}></i>
            </a>
            {selected_customer.primaryPhoneDetails?.value && (
              <a href={`tel:${selected_customer.primaryPhoneDetails.value}`}><i className="fa fa-phone"></i></a>
            )}
            {selected_customer.primaryEmailDetails?.value && (
              <a href={`mailto:${selected_customer.primaryEmailDetails.value}`}><i className="fa fa-envelope"></i></a>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

export default CustomerBasicInfo;
