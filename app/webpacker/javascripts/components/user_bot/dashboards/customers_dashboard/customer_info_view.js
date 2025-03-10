"use strict"

import React, { useState } from "react";
import moment from "moment-timezone";
import { useHistory } from "react-router-dom";
import Popup from "reactjs-popup";

import { useGlobalContext } from "context/user_bots/customers_dashboard/global_state";
import CustomerBasicInfo from "./customer_basic_info";
import { BottomNavigationBar, NotificationMessages } from "shared/components"
import CustomerNav from "./customer_nav";
import { zeroPad } from "libraries/helper";
import { getMomentLocale } from "libraries/helper";

const BottomBar = () => {
  const { selected_customer, props, dispatch, deleteCustomer } = useGlobalContext()
  let history = useHistory();

  return (
    <BottomNavigationBar klassName="centerize">
      {selected_customer && (
        <Popup
          modal
          trigger={
            <button className="btn btn-orange btn-circle btn-delete btn-tweak btn-with-word">
              <i className="fa fa-trash fa-2x" aria-hidden="true"></i>
              <div className="word">{I18n.t("action.delete")}</div>
            </button>
          }>
            {close => (
              <div>
                <div className="modal-body centerize">
                  <div className="margin-around">
                    {I18n.t("user_bot.dashboards.customer.delete_confirmation_message")}
                  </div>
                </div>
                <div className="modal-footer flex justify-between">
                  <button
                    className="btn btn-orange"
                    onClick={() => {
                      deleteCustomer(selected_customer.id)
                      history.goBack()
                    }}>
                    {I18n.t("action.delete2")}
                  </button>
                  <button
                    className="btn btn-tarco"
                    onClick={close}>
                    {I18n.t("action.cancel")}
                  </button>
                </div>
              </div>
            )}
        </Popup>
      )}
      <span>
        {props.i18n.updated_date} {selected_customer.lastUpdatedAt}({zeroPad(selected_customer?.id || 0, 7)})
      </span>
      <button
        className="btn btn-yellow btn-circle btn-save btn-with-word btn-tweak btn-extend-right"
        onClick={() => dispatch({type: "CHANGE_VIEW", payload: { view: "customer_info_form" }})} >
        <i className="fa fa-user-edit fa-2x"></i>
        <div className="word">{I18n.t("action.edit")}</div>
      </button>
    </BottomNavigationBar>
  )
}

const PhoneIcon = ({phone}) => {
  var icon_type;
  switch (phone.type) {
    case "home":
      icon_type = phone.type;
      break;
    case "mobile":
      icon_type = "mobile-alt";
      break;
    case "work":
      icon_type = "building";
      break;
    default:
      icon_type = "phone"
      break;
  }
  return (
    <a href={`tel:${phone.value}`} className="btn btn-tarco btn-icon">
      <i className={`fa fa-${icon_type} fa-2x`} aria-hidden="true" title={phone.type}></i>
    </a>
  )
};

const EmailIcon = ({email}) => {
  var icon_type;
  switch (email.type) {
    case "home":
      icon_type = email.type;
      break;
    case "mobile":
      icon_type = "mobile-alt";
      break;
    case "work":
      icon_type = "building";
      break;
    default:
      icon_type = "envelope"
      break;
  }
  return (
    <a href={`mailto:${email.value}`} className="btn btn-tarco btn-icon">
      <i className={`fa fa-${icon_type} fa-2x`} aria-hidden="true" title={email.type}></i>
    </a>
  )
};

const UserBotCustomerInfoView = () => {
  const { selected_customer, props } = useGlobalContext()
  const { i18n } = props
  const locale = props?.locale || 'ja';
  moment.locale(getMomentLocale(locale));

  return (
    <div className="customer-view">
      <CustomerBasicInfo />
      <CustomerNav />

      <div className="customer-info">
        <dl className="address">
          <dt>{i18n.line_info}</dt>
          <dd>{selected_customer.socialUserName}</dd>
        </dl>
        <dl className="address">
          <dt>{i18n.address}</dt>
          <dd>{selected_customer.addressDetails?.region}{selected_customer.addressDetails?.city}</dd>
        </dl>
        <dl className="phone">
          <dt>{i18n.phone_number}</dt>
          <dd>
            {(selected_customer.phoneNumbersDetails || []).map((phoneNumber, index) => <PhoneIcon key={`${phoneNumber.value}-${index}`} phone={phoneNumber} />)}
          </dd>
        </dl>
        <dl className="email">
          <dt>{i18n.email}</dt>
          <dd>
            {(selected_customer.emailsDetails || []).filter(email => email.value).map((email, index) => <EmailIcon key={`${email.value}-${index}`} email={email} />)}
          </dd>
        </dl>
        <dl className="customerID">
          <dt>{i18n.customer_id}</dt>
          <dd>{selected_customer.customId}</dd>
        </dl>
        <dl className="dob">
          <dt>{i18n.birthday}</dt>
          <dd>
            {selected_customer.birthday ? moment(selected_customer.birthday).format('LL') : null }
          </dd>
        </dl>
        <dl className="memo">
          <dt>{i18n.memo}</dt>
          <dd>{selected_customer.memo}</dd>
        </dl>
        <dl className="tags">
          <dt>{I18n.t("user_bot.dashboards.settings.membership.episodes.tag_input_placeholder")}</dt>
          <dd>{(selected_customer.tags || []).join(", ")}</dd>
        </dl>
      </div>

      <BottomBar />
    </div>
  )
}

export default UserBotCustomerInfoView;
