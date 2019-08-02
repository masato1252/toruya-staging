import React from "react";
import { Field } from "react-final-form";
import { FieldArray } from 'react-final-form-arrays';
import _ from "lodash";

import { setProperListHeight } from "../../../libraries/helper";

const CustomerFields = ({ fields, customer_field, customer_index, all_values, is_editable }) => {
  const customer_state = _.get(all_values, `${customer_field}state`)

  // XXX: depending on ReservationCustomer::ACTIVE_STATES
  const hidden = (customer_state !== "accepted" && customer_state !== "pending")

  return (
    <dl key={`customer_field_${customer_index}`} className={`customer-option ${hidden ? "display-hidden" : ""}`}>
      {["customer_id", "state", "booking_page_id", "booking_option_id",
        "booking_amount_cents", "booking_amount_currency", "tax_include", "booking_at", "details"].map((attr_name, attr_index) => (
          <Field
            key={`${customer_field}${attr_index}`}
            name={`${customer_field}${attr_name}`}
            type="hidden"
            component="input"
          />
      ))}
      <dd className="customer-symbol">
        <span className={`customer-reservation-state ${customer_state}`}>
          <i className="fa fa-user"></i>
        </span>
      </dd>
      <dt>
        <p>{_.get(all_values, `${customer_field}label`)}</p>
        <p className="place">{_.get(all_values, `${customer_field}address`)}</p>
      </dt>
      <dd onClick={(event) => {
        if (!is_editable) return
        event.preventDefault();
        fields.remove(customer_index)
        }}>
        <span className={`btn btn-yellow btn-symbol customer-remove-symbol glyphicon glyphicon-remove ${!is_editable ? "disabled" : ""}`}>
          <i className="fa fa-times" aria-hidden="true"></i>
        </span>
      </dd>
    </dl>
  )
}

const CustomersList = ({ fields, all_values, i18n, reservation_properties, list_height, addCustomer, ...rest }) => {
  const {
    customers_list_label,
    overlap_booking,
    become_overbooking,
    reserved,
    full_seat,
    number,
    add_customer_btn,
    accept,
    pending,
  } = i18n;
  const {
    is_customers_readable,
    is_editable,
  } = reservation_properties;

  const customer_max_load_capability = all_values.reservation_form.customer_max_load_capability
  // XXX: depending on ReservationCustomer::ACTIVE_STATES
  const customers_number = fields.map((customer_field) => _.get(all_values, `${customer_field}state`)).filter((state) => state === "accepted" || state === "pending" ).length;
  let warning_content;

  if (customers_number !== 0) {
    if (customers_number > customer_max_load_capability) {
      warning_content = <dl><span className="warning with-symbol">{overlap_booking}</span></dl>
    }
    else if (customers_number === customer_max_load_capability) {
      warning_content = <dl><span className="warning with-symbol">{become_overbooking}</span></dl>
    }
  }

  return (
    <div id="customers">
      <h2>
        <i className="fa fa-user-plus" aria-hidden="true"></i>
        {customers_list_label}
        <span className="customers-seats-state">
          {reserved}<span className={`number ${customers_number > customer_max_load_capability ? "warning" : ""}`}>{customers_number}</span>{number}/{full_seat}{customer_max_load_capability}{number}
        </span>
      </h2>
      <div
        id="customerList"
        style={{height: list_height}}>
        {fields.map((field, index) => {
          return (
            <CustomerFields
              key={`${field}${index}`}
              fields={fields}
              customer_field={field}
              customer_index={index}
              all_values={all_values}
              is_editable={is_editable}
              {...rest}
            />
          )
        })}
        {
          is_customers_readable && is_editable && (
            <dl onClick={addCustomer} className="add-customer">
              <i className="fa fa-plus fa-2x" aria-hidden="true"></i>
              <div>
                {add_customer_btn}
              </div>
            </dl>
          )
        }
        {warning_content}
      </div>
      <div id="customerLevels">
        <ul>
          <li>
            <span className="customer-reservation-state accepted">
              <i className="fa fa-user"></i>
            </span>
            <span>{accept}</span>
          </li>
          <li>
            <span className="customer-reservation-state pending">
              <i className="fa fa-user"></i>
            </span>
            <span>{pending}</span>
          </li>
        </ul>
      </div>
    </div>
  )
}
class ReservationCustomersList extends React.Component {
  state = {
    listHeight: "60vh"
  };

  componentDidMount() {
    setProperListHeight(this, 300);
  };

  render() {
    return (
      <div>
        <FieldArray
          name={this.props.collection_name}
          collection_name={this.props.collection_name}
          component={CustomersList}
          all_values={this.props.all_values}
          reservation_properties={this.props.reservation_properties}
          i18n={this.props.i18n}
          list_height={this.state.listHeight}
          addCustomer={this.props.addCustomer}
        />
      </div>
    );
  }
}

export default ReservationCustomersList
