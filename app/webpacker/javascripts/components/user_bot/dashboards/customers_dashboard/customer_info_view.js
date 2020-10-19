"use strict"

import React, { useContext } from "react";
import { GlobalContext } from "context/user_bots/customers_dashboard/global_state";
import CustomerBasicInfo from "./customer_basic_info";
import { BottomNavigationBar, NotificationMessages } from "shared/components"
import CustomerNav from "./customer_nav";

const BottomBar = () => {
  const { selected_customer } = useContext(GlobalContext)

  return (
    <BottomNavigationBar klassName="center">
      <span>更新日 {selected_customer.lastUpdatedAt}</span>
    </BottomNavigationBar>
  )
}

const PhoneIcon = ({phone}) => {
  var icon_type;
  switch (phone.type) {
    case "home":
    case "mobile":
      icon_type = phone.type;
      break;
    case "work":
      icon_type = "building";
      break;
    default:
      icon_type = "phone"
      break;
  }
  return (
    <a href={`tel:${phone.value}`} className="BTNtarco">
      <i className={`fa fa-${icon_type} fa-2x`} aria-hidden="true" title={phone.type}></i>
    </a>
  )
};

const EmailIcon = ({email}) => {
  var icon_type;
  switch (email.type) {
    case "home":
    case "mobile":
      icon_type = email.type;
      break;
    case "work":
      icon_type = "building";
      break;
    default:
      icon_type = "envelope"
      break;
  }
  return (
    <a href={`mail:${email.value.address}`} className="BTNtarco">
      <i className={`fa fa-${icon_type} fa-2x`} aria-hidden="true" title={email.type}></i>
    </a>
  )
};

const UserBotCustomerInfoView = () => {
  const { selected_customer, props } = useContext(GlobalContext)
  const { i18n } = props

  return (
    <div className="customer-view">
      <CustomerBasicInfo />
      <CustomerNav />

      <div className="customer-info">
        <dl className="address">
          <dt>{i18n.address}</dt>
          <dd>{selected_customer.address}</dd>
        </dl>
        <dl className="phone">
          <dt>{i18n.phone_number}</dt>
          <dd>
            {(selected_customer.phoneNumbers || []).map((phoneNumber) => <PhoneIcon key={phoneNumber.value} phone={phoneNumber} />)}
          </dd>
        </dl>
        <dl className="email">
          <dt>{i18n.email}</dt>
          <dd>
            {(selected_customer.emails || []).map((email) => <EmailIcon key={email.value.address} email={email} />)}
          </dd>
        </dl>
        <dl className="customerID">
          <dt>顧客ID</dt>
          <dd>{selected_customer.customId}</dd>
        </dl>
        <dl className="dob">
          <dt>{i18n.birthday}</dt>
          <dd>
            {selected_customer.birthday ? `${selected_customer.birthday.year}年${selected_customer.birthday.month}月${selected_customer.birthday.day}日` : null }
          </dd>
        </dl>
        <dl className="memo">
          <dt>{i18n.memo}</dt>
          <dd>{selected_customer.memo}</dd>
        </dl>
      </div>

      <BottomBar />
    </div>
  )
}

export default UserBotCustomerInfoView;
