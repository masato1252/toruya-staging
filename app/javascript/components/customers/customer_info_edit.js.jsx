"use strict";

import React from "react";
import _ from "underscore";
import Select from "../shared/select.js";

class CustomerInfoEdit extends React.Component {
  constructor(props) {
    super(props);

    this.optionMapping = {
      home: this.props.homeLabel,
      mobile: this.props.mobileLabel,
      work: this.props.workLabel
    }
  };

  optionMappingLabel = (type) => {
    if (this.optionMapping[type]) {
      return this.optionMapping[type];
    }
    else {
      return type;
    }
  };

  handleCreateCustomer = (event) => {
    event.preventDefault();
    var _this = this;
    var valuesToSubmit = $(this.customerForm).serialize();

    this.props.switchProcessing(function(){
      $.ajax({
        type: "POST",
        url: _this.props.saveCustomerPath, //sumbits it to the given url of the form
        data: valuesToSubmit,
        dataType: "JSON"
      }).success(function(result) {
        _this.props.handleCreatedCustomer(result["customer"]);
        _this.props.forceStopProcessing();
        _this.props.switchEditMode();
      }).always(function() {
        _this.props.forceStopProcessing();
      });
    })
  };

  itemOptions = (items) => {
    var defaultOptions = [
      { label: this.props.homeLabel, value: "home" },
      { label: this.props.mobileLabel, value: "mobile" },
      { label: this.props.workLabel, value: "work" }
    ];

    (items || []).forEach(function(item) {
      var options = defaultOptions.map(function(option) {
        return (
          option["value"]
        );
      })

      if (!_.contains(options, item.type)) {
        defaultOptions.push(
          { label: item.type, value: item.type }
        )
      }
    });

    return defaultOptions;
  };

  _selectedRank = () => {
    return _.find(this.props.ranks, function(rank) { return rank.value == this.props.customer.rankId; }.bind(this))
  };

  _selectedRankClass = () => {
    return this._selectedRank() ? this._selectedRank().key : 'regular'
  };

  displayFuzzyEmail = (email) => {
    return email.replace(/(.).*(@.*)/, '$1***$2');
  };

  displayFuzzyPhone = (phone) => {
    return phone.replace(/\w+(\w\w\w\w)/, '***$1');
  };

  render() {
    return (
      <div id="customerInfoEdit" className="contBody">
        <form
          id="customer-edit-form"
          ref={(c) => {this.customerForm = c}}
          acceptCharset="UTF-8"
          action={this.props.saveCustomerPath}
          method="post">
          {
            this.props.customer.id ? (
              <input type="hidden" name="customer[id]" value={this.props.customer.id} />
            ) : null
          }
          {
            this.props.customer.otherAddresses ? (
              <input type="hidden" name="customer[other_addresses]" value={this.props.customer.otherAddresses } />
            ) : null
          }
          <input name="authenticity_token" type="hidden" value={this.props.formAuthenticityToken} />
        <div id="basic">
          <dl>
            <dt>
              <ul>
                <li>
                  <Select
                    options={this.props.contactGroups}
                    value={this.props.customer.contactGroupId || ""}
                    name="customer[contact_group_id]"
                    data-name="contactGroupId"
                    onChange={this.props.handleCustomerDataChange}
                  />
                </li>
                <li>
                  <Select
                    id="customerSts"
                    className={this._selectedRankClass()}
                    options={this.props.ranks}
                    value={this.props.customer.rankId || ""}
                    name="customer[rank_id]"
                    data-name="rankId"
                    onChange={this.props.handleCustomerDataChange}
                    />
                </li>
              </ul>
            </dt>
            <dd>
              <ul>
                <li>
                  <input
                    type="text"
                    id="familyNameKana"
                    placeholder="せい"
                    value={this.props.customer.phoneticLastName || ""}
                    name="customer[phonetic_last_name]"
                    data-name="phoneticLastName"
                    onChange={this.props.handleCustomerDataChange}
                    />
                </li>
                <li>
                  <input
                    type="text"
                    id="firstNameKana"
                    placeholder="めい"
                    value={this.props.customer.phoneticFirstName || ""}
                    name="customer[phonetic_first_name]"
                    data-name="phoneticFirstName"
                    onChange={this.props.handleCustomerDataChange}
                    />
                </li>
              </ul>
              <ul>
                <li>
                  <input
                    type="text"
                    id="familyName"
                    placeholder="姓"
                    value={this.props.customer.lastName || ""}
                    name="customer[last_name]"
                    data-name="lastName"
                    onChange={this.props.handleCustomerDataChange}
                    />
                </li>
                <li>
                  <input
                    type="text"
                    id="firstName"
                    placeholder="名"
                    value={this.props.customer.firstName || ""}
                    name="customer[first_name]"
                    data-name="firstName"
                    onChange={this.props.handleCustomerDataChange}
                    />
                </li>
              </ul>
            </dd>
            <dd>
              <ul>
                <li>
                  <i className="fa fa-phone" aria-hidden="true" title="call"></i>

                  <Select
                    prefix="primaryPhone"
                    options={(this.props.customer.phoneNumbers || []).map(function(phoneNumber, i) {
                      let fuzzyMode = (!this.props.customerEditPermission && i < this.props.customer.phoneNumbersOriginal.length)

                      return({
                        label: (
                          fuzzyMode ? `${this.optionMappingLabel(phoneNumber.type)} ${this.displayFuzzyPhone(phoneNumber.value)}`
                          :
                          `${this.optionMappingLabel(phoneNumber.type)} ${phoneNumber.value}`
                        ),
                        value: `${phoneNumber.type}${this.props.delimiter}${phoneNumber.value}`
                      })
                    }.bind(this))}
                    value={this.props.customer.primaryPhone && this.props.customer.primaryPhone.type && this.props.customer.primaryPhone.value ? `${this.props.customer.primaryPhone.type}${this.props.delimiter}${this.props.customer.primaryPhone.value}` : ""}
                    name="customer[primary_phone]"
                    data-name="primaryPhone"
                    onChange={this.props.handleCustomerGoogleDataChange}
                    />
                </li>
              </ul>
              <ul>
                <li>
                  <i className="fa fa-envelope" aria-hidden="true" title="mail"></i>
                  <Select
                    prefix="primaryEmail"
                    options={(this.props.customer.emails || []).map(function(email, i) {
                      let fuzzyMode = (!this.props.customerEditPermission && i < this.props.customer.emailsOriginal.length)

                      return({
                        label: fuzzyMode ? `${this.optionMappingLabel(email.type)} ${this.displayFuzzyEmail(email.value.address)}` : `${this.optionMappingLabel(email.type)} ${email.value.address}`,
                        value: `${email.type}${this.props.delimiter}${email.value.address}`
                      })
                    }.bind(this))}
                    value={this.props.customer.primaryEmail && this.props.customer.primaryEmail.type && this.props.customer.primaryEmail.value ? `${this.props.customer.primaryEmail.type}${this.props.delimiter}${this.props.customer.primaryEmail.value.address}` : ""}
                    name="customer[primary_email]"
                    data-name="primaryEmail"
                    onChange={this.props.handleCustomerGoogleDataChange}
                    />
                </li>
              </ul>
            </dd>
          </dl>
        </div>

      <div id="tabs" className="tabs">
        <a href="#" className="" onClick={this.props.switchReservationMode}>利用履歴</a>
        <a href="#" className="here">顧客情報</a>
      </div>
      <div id="detailInfo" className="tabBody" style={{height: "425px"}}>
        <ul className="functions">
          <li className="left">
            {
              this.props.customer.id ? (
                <a href="#" onClick={this.props.switchEditMode}>
                  <i className="fa fa-chevron-left" aria-hidden="true">
                  </i>&nbsp;{this.props.backWithoutSaveBtn}
                </a>
              ) : null
            }
          </li>
          <li className="right">
            更新日 {this.props.customer.lastUpdatedAt} {this.props.customer.updatedByUserName}
          </li>
        </ul>

        <dl className="Address">
          <dt>{this.props.addressLabel}</dt>
          <dd className={this.props.addressEditPermission ? "" : "display-hidden"}>
            <ul className="addrzip">
              <li className="zipcode">〒
                <input
                  type="hidden"
                  value={this.props.customer.primaryAddress && this.props.customer.primaryAddress.type ? this.props.customer.primaryAddress.type : "home"}
                  name="customer[primary_address][type]"
                  />
                <input
                  id="zipcode3"
                  type="text"
                  maxLength="3"
                  size="3"
                  tabIndex="1"
                  value={this.props.customer.primaryAddress && this.props.customer.primaryAddress.value && this.props.customer.primaryAddress.value.postcode1 ? this.props.customer.primaryAddress.value.postcode1 : ""}
                  name="customer[primary_address][postcode1]"
                  data-name="primaryAddress-postcode1"
                  onChange={this.props.handleCustomerGoogleDataChange}
                  />
                &nbsp;—&nbsp;
                <input
                  ref="zipcode4"
                  id="zipcode4"
                  type="text"
                  maxLength="4"
                  size="4"
                  tabIndex="2"
                  value={this.props.customer.primaryAddress && this.props.customer.primaryAddress.value && this.props.customer.primaryAddress.value.postcode2 ? this.props.customer.primaryAddress.value.postcode2 : ""}
                  name="customer[primary_address][postcode2]"
                  data-name="primaryAddress-postcode2"
                  onChange={this.props.handleCustomerGoogleDataChange}
                  />
              </li>
            </ul>
            <ul className="addrStateCity">
              <li className="state">
                <Select
                  includeBlank="true"
                  blankOption={this.props.selectRegionLabel}
                  options={this.props.regions}
                  value={this.props.customer.primaryAddress && this.props.customer.primaryAddress.value && this.props.customer.primaryAddress.value.region ? this.props.customer.primaryAddress.value.region : ""}
                  name="customer[primary_address][region]"
                  data-name="primaryAddress-region"
                  onChange={this.props.handleCustomerGoogleDataChange}
                  />
              </li>
              <li className="city">
                <input
                  type="text"
                  id="city"
                  placeholder={this.props.cityPlaceholder}
                  value={this.props.customer.primaryAddress && this.props.customer.primaryAddress.value && this.props.customer.primaryAddress.value.city ? this.props.customer.primaryAddress.value.city : ""}
                  name="customer[primary_address][city]"
                  data-name="primaryAddress-city"
                  onChange={this.props.handleCustomerGoogleDataChange}
                  />
              </li>
            </ul>
            <ul className="addrRest">
              <li className="address1">
                <input
                  type="text"
                  placeholder={this.props.address1Placeholder}
                  value={this.props.customer.primaryAddress && this.props.customer.primaryAddress.value && this.props.customer.primaryAddress.value.street1 ? this.props.customer.primaryAddress.value.street1 : ""}
                  name="customer[primary_address][street1]"
                  data-name="primaryAddress-street1"
                  onChange={this.props.handleCustomerGoogleDataChange}
                  />
              </li>
              <li className="address1">
                <input
                  type="text"
                  placeholder={this.props.address2Placeholder}
                  value={this.props.customer.primaryAddress && this.props.customer.primaryAddress.value && this.props.customer.primaryAddress.value.street2 ? this.props.customer.primaryAddress.value.street2 : ""}
                  name="customer[primary_address][street2]"
                  data-name="primaryAddress-street2"
                  onChange={this.props.handleCustomerGoogleDataChange}
                  />
              </li>
            </ul>
          </dd>
          <dd className={!this.props.addressEditPermission ? "" : "display-hidden"}>
            {this.props.customer.address}
          </dd>
        </dl>
        <dl className="phone">
          <dt>
            {this.props.phoneLabel}
            <a onClick={this.props.addOption.bind(null, "phoneNumbers")}
              className="BTNtarco"
              title="追加">
            <i className="fa fa-plus" aria-hidden="true"></i></a>
          </dt>
            <dd>
              <ul>
                {
                  (this.props.customer.phoneNumbers || []).map(function(phoneNumber, i) {
                    let fuzzyMode = (!this.props.customerEditPermission && i < this.props.customer.phoneNumbersOriginal.length)

                    return (
                      <li key={`phoneNumber-${i}`}>
                        <Select
                          prefix="phoneNumber"
                          options={this.itemOptions(this.props.customer.phoneNumbers)}
                          value={phoneNumber.type}
                          name="customer[phone_numbers][][type]"
                          data-name="phoneNumbers-type"
                          data-value-name={`phoneNumbers-type-${i}`}
                          onChange={this.props.handleCustomerGoogleDataChange}
                          disabled={fuzzyMode}
                          />
                        <input
                          type="hidden"
                          value={phoneNumber.type}
                          name="customer[phone_numbers][][type]"
                          disabled={!fuzzyMode}
                          />
                        <input
                          type="tel"
                          value={fuzzyMode ? this.displayFuzzyPhone(phoneNumber.value) : phoneNumber.value}
                          data-name={`phoneNumbers-value-${i}`}
                          name="customer[phone_numbers][][value]"
                          data-name="phoneNumbers-value"
                          data-value-name={`phoneNumbers-value-${i}`}
                          onChange={this.props.handleCustomerGoogleDataChange}
                          disabled={fuzzyMode}
                          />
                        <input
                          type="hidden"
                          value={phoneNumber.value}
                          name="customer[phone_numbers][][value]"
                          disabled={!fuzzyMode}
                          />
                        <a onClick={this.props.removeOption.bind(null, "phoneNumbers", i)}
                          className={`BTNyellow ${fuzzyMode && "disabled"}`}
                          title="DELETE">
                          <i className="fa fa-minus" aria-hidden="true" title="DELETE"></i>
                        </a>
                      </li>
                    )
                  }.bind(this))
                }
              </ul>
            </dd>
          </dl>
          <dl className="email">
            <dt>
              {this.props.emailLabel}
              <a onClick={this.props.addOption.bind(null, "emails")}
                className="BTNtarco"
                title="追加">
              <i className="fa fa-plus" aria-hidden="true"></i></a>
            </dt>
            <dd>
            <ul>
                {
                  (this.props.customer.emails || []).map(function(email, i) {
                    let fuzzyMode = (!this.props.customerEditPermission && i < this.props.customer.emailsOriginal.length)

                    return (
                      <li key={`email-${i}`}>
                        <Select
                          prefix="email"
                          options={this.itemOptions(this.props.customer.emails)}
                          value={email.type}
                          name="customer[emails][][type]"
                          data-name="emails-type"
                          data-value-name={`emails-type-${i}`}
                          onChange={this.props.handleCustomerGoogleDataChange}
                          disabled={fuzzyMode}
                          />
                        <input
                          type="hidden"
                          value={email.type}
                          name="customer[emails][][type]"
                          disabled={!fuzzyMode}
                          />
                        <input
                          type="email"
                          value={fuzzyMode ? this.displayFuzzyEmail(email.value.address) : email.value.address}
                          name="customer[emails][][value][address]"
                          data-name="emails-value"
                          data-value-name={`emails-value-${i}`}
                          onChange={this.props.handleCustomerGoogleDataChange}
                          className={`${fuzzyMode && "disabled"}`}
                          disabled={fuzzyMode}
                          />
                        <input
                          type="hidden"
                          value={email.value.address}
                          name="customer[emails][][value][address]"
                          disabled={!fuzzyMode}
                          />
                        <a onClick={this.props.removeOption.bind(null, "emails", i)}
                          className={`BTNyellow ${fuzzyMode && "disabled"}`}
                          title="DELETE">
                          <i className="fa fa-minus" aria-hidden="true" title="DELETE"></i>
                        </a>
                      </li>
                    )
                  }.bind(this))
                }
              </ul>
            </dd>
          </dl>
          <dl className="customerID">
            <dt><label htmlFor="customerID">{this.props.customerIdPlaceholder}</label></dt>
            <dd>
              <input
                type="text"
                name="customer[custom_id]"
                placeholder={this.props.customerIdPlaceholder}
                value={this.props.customer.customId || ""}
                data-name="customId"
                onChange={this.props.handleCustomerDataChange}
                />
            </dd>
          </dl>
          <dl className="dob">
            <dt><label htmlFor="dob">{this.props.birthdayLabel}</label></dt>
            <dd>
              <Select
                id="dobYear"
                includeBlank="true"
                blankOption={this.props.selectYearLabel}
                options={this.props.yearOptions}
                value={this.props.customer.birthday ? this.props.customer.birthday.year : ""}
                name="customer[dob][year]"
                data-name="birthday-year"
                onChange={this.props.handleCustomerDataChange}
                />年
              <Select
                id="dobMonth"
                includeBlank="true"
                blankOption={this.props.selectMonthLabel}
                options={this.props.monthOptions}
                value={this.props.customer.birthday ? this.props.customer.birthday.month : ""}
                name="customer[dob][month]"
                data-name="birthday-month"
                onChange={this.props.handleCustomerDataChange}
                />月
              <Select
                id="dobDay"
                includeBlank="true"
                blankOption={this.props.selectDayLabel}
                options={this.props.dayOptions}
                value={this.props.customer.birthday ? this.props.customer.birthday.day : ""}
                name="customer[dob][day]"
                data-name="birthday-day"
                onChange={this.props.handleCustomerDataChange}
                />日
            </dd>
          </dl>
          <dl className="memo">
            <dt><label htmlFor="memo">{this.props.memoLabel}</label></dt>
            <dd>
              <textarea
                placeholder="Memo"
                cols="30"
                rows="5"
                name="customer[memo]"
                data-name="memo"
                value={this.props.customer.memo ? this.props.customer.memo : ""}
                onChange={this.props.handleCustomerDataChange}
                />
            </dd>
          </dl>
      </div>
      </form>
    </div>
    );
  }
};

export default CustomerInfoEdit;
