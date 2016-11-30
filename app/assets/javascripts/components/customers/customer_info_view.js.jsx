"use strict";

UI.define("Customers.CustomerInfoView", function() {
  var CustomerInfoView = React.createClass({
    getInitialState: function() {
      return ({
      });
    },

    phoneRender: function(phone) {
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
        <a key={phone.value} href={`mail:${phone.value}`} className="BTNtarco">
          <i className={`fa fa-${icon_type} fa-2x`} aria-hidden="true" title={phone.type}></i>
        </a>
      )
    },

    emailRender: function(email) {
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
        <a key={email.value.address} href={`tel:${email.value.address}`} className="BTNtarco">
          <i className={`fa fa-${icon_type} fa-2x`} aria-hidden="true" title={email.type}></i>
        </a>
      )
    },

    render: function() {
      return (
        <div id="customerInfo" className="contBody">
          <div id="basic">
            <dl>
              <dt>
                <ul>
                  {this.props.customer.groupName ?
                    <li>{this.props.customer.groupName}</li> : null
                  }
                  {
                    this.props.customer.rank ?
                      <li className={this.props.customer.rank.key}>{this.props.customer.rank.name}</li> : null
                  }
                </ul>
              </dt>
              <dd>
                <ul className="kana">
                  <li>{this.props.customer.phoneticLastName} {this.props.customer.phoneticFirstName}</li>
                </ul>
                <ul><li>{this.props.customer.lastName} {this.props.customer.firstName}</li></ul>
              </dd>
              <dd>
                {
                  this.props.customer.primaryPhone && this.props.customer.primaryPhone.value ? (
                    <a href={`tel:${this.props.customer.primaryPhone.value}`} className="BTNtarco">
                      <i className={`fa fa-phone fa-2x`}aria-hidden="true" title="call"></i>
                    </a>
                  ) : null
                }
                {
                  this.props.customer.primaryEmail && this.props.customer.primaryEmail.value ? (
                    <a href={`mail:${this.props.customer.primaryEmail.value.address}`} className="BTNtarco">
                      <i className="fa fa-envelope fa-2x" aria-hidden="true" title="mail"></i>
                    </a>
                  ) : null
                }
              </dd>
            </dl>
          </div>

          <div id="tabs" className="tabs">
            <a href="#" className="" onClick={this.props.switchReservationMode}>利用履歴</a>
            <a href="#" className="here">顧客情報</a>
          </div>
          <div id="detailInfo" className="tabBody" style={{height: "425px"}}>
            <ul className="functions">
              <li className="right">
                <a href="#" onClick={this.props.switchEditMode}>{this.props.editBtn}</a>
              </li>
            </ul>
            <dl className="Address">
              <dt>{this.props.addressLabel}</dt>
              <dd>{this.props.customer.displayAddress}</dd>
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
              <dl className="customerID"><dt>顧客ID</dt><dd>{this.props.customer.customerId}</dd></dl>
              <dl className="dob"><dt>{this.props.birthdayLabel}</dt>
              <dd>
                {this.props.customer.birthday ? `${this.props.customer.birthday.year}-${this.props.customer.birthday.month}-${this.props.customer.birthday.day}` : null }
              </dd></dl>
              <dl className="memo"><dt>{this.props.memoLabel}</dt><dd>{this.props.customer.memo}</dd></dl>
            </div>
          </div>
        </div>
      );
    }
  });

  return CustomerInfoView;
});
