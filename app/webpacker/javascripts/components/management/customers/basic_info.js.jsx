
import React from "react";

class CustomerBasicInfo extends React.Component {
  render() {
    return (
      <div id="basic">
        <dl>
          <dt>
            <ul>
              <li className={this.props.customer.groupName ? "" : "field-error"}>{this.props.customer.groupName ? this.props.customer.groupName : this.props.groupBlankOption}</li>
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
              this.props.customer.detailsReadable && this.props.customer.id ? (
                <a href="#" onClick={this.props.switchCustomerReminderPermission} className="BTNtarco" data-id="customer-reminder-toggler">
                  <i className={`customer-reminder-permission fa fa-bell fa-2x ${this.props.customer.reminderPermission ? "reminder-on" : ""}`} aria-hidden="true" title="Bell"></i>
                </a>
              ) : null
            }
            {
              this.props.customer.detailsReadable && this.props.customer.primaryPhone && this.props.customer.primaryPhone.value ? (
                <a href={`tel:${this.props.customer.primaryPhone.value}`} className="BTNtarco">
                  <i className={`fa fa-phone fa-2x`} aria-hidden="true" title="call"></i>
                </a>
              ) : null
            }
            {
              this.props.customer.detailsReadable && this.props.customer.primaryEmail && this.props.customer.primaryEmail.value ? (
                <a href={`mail:${this.props.customer.primaryEmail.value.address}`} className="BTNtarco">
                  <i className="fa fa-envelope fa-2x" aria-hidden="true" title="mail"></i>
                </a>
              ) : null
            }
          </dd>
        </dl>
      </div>
    );
  }
}

export default CustomerBasicInfo;
