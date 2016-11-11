//= require "components/shared/select"

"use strict";

UI.define("Customers.CustomerInfoEdit", function() {
  var CustomerInfoEdit = React.createClass({
    getInitialState: function() {
      return ({
      });
    },

    handleCreateCustomer: function(event) {
      event.preventDefault();

      var _this = this;

      // if (this.isCustomerdataValid()) {
        var valuesToSubmit = $(this.customerForm).serialize();

        $.ajax({
          type: "POST",
          url: this.props.saveCustomerPath, //sumbits it to the given url of the form
          data: valuesToSubmit,
          dataType: "JSON"
        }).success(function(result){
          _this.props.handleCreatedCustomer(result["customer"]);
          // _this.state.customers.unshift(result["customer"])
          // _this.setState({customers: _this.state.customers, customer: {}, selected_customer_id: ""});
        });
      // }
    },


    itemOptions: function(items) {
      var defaultOptions = [
        { label: "Home", value: "home" },
        { label: "Mobile", value: "mobile" },
        { label: "Work", value: "work" }
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
    },

    render: function() {
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
                    <UI.Select
                      options={this.props.contactGroups}
                      value={this.props.customer.contactGroupId}
                      name="customer[contact_group_id]"
                      data-name="contactGroupId"
                      onChange={this.props.handleCustomerDataChange}
                    />
                  </li>
                  <li>
                    <UI.Select
                      id="customerSts"
                      className={this.props.customer.rank ? this.props.customer.rank.key : 'regular'}
                      options={this.props.ranks}
                      value={this.props.customer.rankId}
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
                      id="familyName"
                      placeholder="姓"
                      value={this.props.customer.lastName}
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
                      value={this.props.customer.firstName}
                      name="customer[first_name]"
                      data-name="firstName"
                      onChange={this.props.handleCustomerDataChange}
                      />
                  </li>
                </ul>
                <ul>
                  <li>
                    <input
                      type="text"
                      id="familyNameKana"
                      placeholder="せい"
                      value={this.props.customer.phoneticLastName}
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
                      value={this.props.customer.phoneticFirstName}
                      name="customer[phonetic_first_name]"
                      data-name="phoneticFirstName"
                      onChange={this.props.handleCustomerDataChange}
                      />
                  </li>
                </ul>
              </dd>
              <dd>
                <ul>
                  <li>
                    <i className="fa fa-phone" aria-hidden="true" title="call"></i>

                    <UI.Select
                      prefix="primaryPhone"
                      options={(this.props.customer.phoneNumbers || []).map(function(phoneNumber) {
                        return({
                          label: `[${phoneNumber.type}] ${phoneNumber.value}`,
                          value: `${phoneNumber.type}${this.props.delimiter}${phoneNumber.value}`
                        })
                      }.bind(this))}
                      value={this.props.customer.primaryPhone ? `${this.props.customer.primaryPhone.type}${this.props.delimiter}${this.props.customer.primaryPhone.value}` : ""}
                      name="customer[primary_phone]"
                      data-name="primaryPhone"
                      onChange={this.props.handleCustomerGoogleDataChange}
                      />
                  </li>
                </ul>
                <ul>
                  <li>
                    <i className="fa fa-envelope" aria-hidden="true" title="mail"></i>
                    <UI.Select
                      prefix="primaryEmail"
                      options={(this.props.customer.emails || []).map(function(email) {
                        return({
                          label: `[${email.type}] ${email.value.address}`,
                          value: `${email.type}${this.props.delimiter}${email.value.address}`
                        })
                      }.bind(this))}
                      value={this.props.customer.primaryEmail.value ? `${this.props.customer.primaryEmail.type}${this.props.delimiter}${this.props.customer.primaryEmail.value.address}` : ""}
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
          <a href="customer.html" className="">利用履歴</a>
          <a href="#" className="here">顧客情報</a>
        </div>
        <div id="detailInfo" className="tabBody" style={{height: "425px"}}>
          <ul className="functions">
            <li className="left">
              <a href="customer_info.html">
                <i className="fa fa-chevron-left" aria-hidden="true">
                </i>&nbsp;Back Without Save
              </a>
            </li>
            <li className="right">
              <a href="#" onClick={this.handleCreateCustomer}>Save</a>
            </li>
          </ul>

          <dl className="Address">
            <dt>Address</dt>
            <dd>
              <ul classname="addrzip">
                <li classname="zipcode">〒
                  <input
                    type="hidden"
                    value={this.props.customer.primaryAddress.type ? this.props.customer.primaryAddress.type : ""}
                    name="customer[primary_address][type]"
                    />
                  <input
                    id="zipcode3"
                    type="number"
                    maxLength="3"
                    size="3"
                    value={this.props.customer.primaryAddress.value ? this.props.customer.primaryAddress.value.postcode1 : ""}
                    name="customer[primary_address][postcode1]"
                    data-name="primaryAddress-postcode1"
                    onChange={this.props.handleCustomerGoogleDataChange}
                    />
                  &nbsp;—&nbsp;
                  <input
                    id="zipcode4"
                    type="number"
                    maxLength="4"
                    size="4"
                    value={this.props.customer.primaryAddress.value ? this.props.customer.primaryAddress.value.postcode2 : ""}
                    name="customer[primary_address][postcode2]"
                    data-name="primaryAddress-postcode2"
                    onChange={this.props.handleCustomerGoogleDataChange}
                    />
                </li>
              </ul>
              <ul className="addrStateCity">
                <li className="state">
                  <UI.Select
                    options={this.props.regions}
                    value={this.props.customer.primaryAddress.value ? this.props.customer.primaryAddress.value.region : ""}
                    name="customer[primary_address][region]"
                    data-name="primaryAddress-region"
                    onChange={this.props.handleCustomerGoogleDataChange}
                    />
                </li>
                <li className="city">
                  <input
                    type="text"
                    id="city"
                    value={this.props.customer.primaryAddress.value ? this.props.customer.primaryAddress.value.city : ""}
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
                    value={this.props.customer.primaryAddress.value ? this.props.customer.primaryAddress.value.street1 : ""}
                    name="customer[primary_address][street1]"
                    data-name="primaryAddress-street1"
                    onChange={this.props.handleCustomerGoogleDataChange}
                    />
                </li>
                <li className="address1">
                  <input
                    type="text"
                    value={this.props.customer.primaryAddress.value ? this.props.customer.primaryAddress.value.street2 : ""}
                    name="customer[primary_address][street2]"
                    data-name="primaryAddress-street2"
                    onChange={this.props.handleCustomerGoogleDataChange}
                    />
                </li>
              </ul>
            </dd>
          </dl>
          <dl className="phone">
            <dt>
              Phone
              <a onClick={this.props.addOption.bind(null, "phoneNumbers")}
                className="BTNtarco"
                title="追加">
              <i className="fa fa-plus" aria-hidden="true"></i></a>
            </dt>
              <dd>
                <ul>
                  {
                    (this.props.customer.phoneNumbers || []).map(function(phoneNumber, i) {
                      return (
                        <li key={`phoneNumber-${i}`}>
                          <UI.Select
                            prefix="phoneNumber"
                            options={this.itemOptions(this.props.customer.phoneNumbers)}
                            value={phoneNumber.type}
                            name="customer[phone_numbers][][type]"
                            data-name="phoneNumbers-type"
                            data-value-name={`phoneNumbers-type-${i}`}
                            onChange={this.props.handleCustomerGoogleDataChange}
                            />
                          <input
                            type="tel"
                            value={phoneNumber.value}
                            data-name={`phoneNumbers-value-${i}`}
                            name="customer[phone_numbers][][value]"
                            data-name="phoneNumbers-value"
                            data-value-name={`phoneNumbers-value-${i}`}
                            onChange={this.props.handleCustomerGoogleDataChange}
                            />
                          <a onClick={this.props.removeOption.bind(null, "phoneNumbers", i)}
                            className="BTNyellow"
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
                Email
                <a onClick={this.props.addOption.bind(null, "emails")}
                  className="BTNtarco"
                  title="追加">
                <i className="fa fa-plus" aria-hidden="true"></i></a>
              </dt>
              <dd>
              <ul>
                  {
                    (this.props.customer.emails || []).map(function(email, i) {
                      return (
                        <li key={`email-${i}`}>
                          <UI.Select
                            prefix="email"
                            options={this.itemOptions(this.props.customer.emails)}
                            value={email.type}
                            name="customer[emails][][type]"
                            data-name="emails-type"
                            data-value-name={`emails-type-${i}`}
                            onChange={this.props.handleCustomerGoogleDataChange}
                            />
                          <input
                            type="email"
                            value={email.value.address}
                            name="customer[emails][][value][address]"
                            data-name="emails-value"
                            data-value-name={`emails-value-${i}`}
                            onChange={this.props.handleCustomerGoogleDataChange}
                            />
                          <a onClick={this.props.removeOption.bind(null, "emails", i)}
                            className="BTNyellow"
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
              <dt><label for="customerID">顧客ID</label></dt>
              <dd><input type="text" id="customerID" placeholder="Customer ID" value="DHS0001" /></dd>
            </dl>
            <dl className="dob">
              <dt><label for="dob">DOB</label></dt>
              <dd>
                <UI.Select
                  id="dobYear"
                  includeBlank="true"
                  blankOption="Select A Year"
                  options={this.props.yearOptions}
                  value={this.props.customer.birthday ? this.props.customer.birthday.year : ""}
                  name="customer[dob][year]"
                  data-name="birthday-year"
                  onChange={this.props.handleCustomerDataChange}
                  />年
                <UI.Select
                  id="dobMonth"
                  includeBlank="true"
                  blankOption="Select A Month"
                  options={this.props.monthOptions}
                  value={this.props.customer.birthday ? this.props.customer.birthday.month : ""}
                  name="customer[dob][month]"
                  data-name="birthday-month"
                  onChange={this.props.handleCustomerDataChange}
                  />月
                <UI.Select
                  id="dobDay"
                  includeBlank="true"
                  blankOption="Select A Day"
                  options={this.props.dayOptions}
                  value={this.props.customer.birthday ? this.props.customer.birthday.day : ""}
                  name="customer[dob][day]"
                  data-name="birthday-day"
                  onChange={this.props.handleCustomerDataChange}
                  />日
              </dd>
            </dl>
            <dl className="memo">
              <dt><label for="memo">Memo</label></dt>
              <dd><textarea id="memo" placeholder="Memo" cols="30" rows="5"></textarea></dd>
            </dl>
        </div>
        </form>
      </div>
      );
    }
  });

  return CustomerInfoEdit;
});
