"use strict";

import React from "react";

import CustomerBasicInfo from "./basic_info.js";

class CustomerInfoView extends React.Component {
  phoneRender = (phone) => {
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
      <a key={phone.value} href={`tel:${phone.value}`} className="BTNtarco">
        <i className={`fa fa-${icon_type} fa-2x`} aria-hidden="true" title={phone.type}></i>
      </a>
    )
  };

  emailRender = (email) => {
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
      <a key={email.value.address} href={`mail:${email.value.address}`} className="BTNtarco">
        <i className={`fa fa-${icon_type} fa-2x`} aria-hidden="true" title={email.type}></i>
      </a>
    )
  };

  render() {
    return (
      <div id="customerInfo" className="contBody">
        <CustomerBasicInfo
          customer={this.props.customer}
          groupBlankOption={this.props.groupBlankOption}
          switchCustomerReminderPermission={this.props.switchCustomerReminderPermission}
        />
        <div id="tabs" className="tabs">
          <a href="#" className="" onClick={this.props.switchReservationMode}>利用履歴</a>
          <a href="#" className="here">顧客情報</a>
        </div>
        <div id="detailInfo" className="tabBody" style={{height: "425px"}}>
          <ul className="functions">
            <li className="left">
            <a href="#" onClick={this.props.switchEditMode}>
              <i className="fa fa-pencil" aria-hidden="true"></i>
              {this.props.editBtn}
            </a>
            </li>
            <li className="right">
              更新日 {this.props.customer.lastUpdatedAt} {this.props.customer.updatedByUserName}
            </li>
          </ul>
          <dl className="Address">
            <dt>{this.props.addressLabel}</dt>
            <dd>{this.props.customer.address}</dd>
          </dl>
          <dl className="phone">
            <dt>{this.props.phoneLabel}</dt>
            <dd>
              {(this.props.customer.phoneNumbers || []).map(function(phoneNumber) {
                return this.phoneRender(phoneNumber);
              }.bind(this))}
            </dd>
          </dl>
          <dl className="email">
            <dt>{this.props.emailLabel}</dt>
            <dd>
              {(this.props.customer.emails || []).map(function(email) {
                return this.emailRender(email);
              }.bind(this))}
            </dd>
          </dl>
          <div className="others">
            <dl className="customerID"><dt>顧客ID</dt><dd>{this.props.customer.customId}</dd></dl>
            <dl className="dob"><dt>{this.props.birthdayLabel}</dt>
            <dd>
              {this.props.customer.birthday ? `${this.props.customer.birthday.year}年${this.props.customer.birthday.month}月${this.props.customer.birthday.day}日` : null }
            </dd></dl>
            <dl className="memo"><dt>{this.props.memoLabel}</dt><dd>{this.props.customer.memo}</dd></dl>
          </div>
        </div>
      </div>
    );
  }
};

export default CustomerInfoView;
