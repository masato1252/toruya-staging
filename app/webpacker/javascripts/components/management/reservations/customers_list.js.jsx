import React from "react";
import { Field } from "react-final-form";
import { FieldArray } from 'react-final-form-arrays';
import _ from "lodash";

import { setProperListHeight } from "../../../libraries/helper";

class CustomerPopup extends React.Component {
  constructor(props) {
    super(props);
  }

  is_selected_customer_approved = () => {
    const {
      accepted_state,
    } = this.props.reservation_properties.reservation_staff_states;

    return this.selected_customer().state === accepted_state;
  }

  selected_customer = () => {
    const {
      selected_customer_id,
      customers_list
    } = this.props.all_values.reservation_form

    return customers_list.find((customer_item) => String(customer_item.customer_id) === String(selected_customer_id))
  }

  selected_customer_index = () => {
    const {
      selected_customer_id,
      customers_list
    } = this.props.all_values.reservation_form

    return customers_list.findIndex((customer_item) => String(customer_item.customer_id) === String(selected_customer_id))
  }

  handleToggleCustomerState = (event) => {
    event.preventDefault();

    const {
      is_editable,
      reservation_staff_states: {
        pending_state,
        accepted_state,
      }
    } = this.props.reservation_properties

    if (!is_editable) return

    const {
      customers_list
    } = this.props.all_values.reservation_form

    let new_customer_list = _.clone(customers_list)
    new_customer_list[this.selected_customer_index()]["state"] = this.is_selected_customer_approved() ? pending_state : accepted_state

    this.props.reservation_form.change("reservation_form[customers_list]", new_customer_list)

    $("#customer-modal").modal("hide")
  }

  handleCustomerDelete = (event) => {
    const {
      is_editable,
    } = this.props.reservation_properties

    const {
      customers_list
    } = this.props.all_values.reservation_form

    if (!is_editable) return
    event.preventDefault();

    let new_customer_list = _.clone(customers_list)

    if (this.selected_customer().binding) {
      new_customer_list[this.selected_customer_index()]["state"] = "canceled"
    }
    else {
      new_customer_list.splice(this.selected_customer_index(), 1)
    }

    this.props.reservation_form.change("reservation_form[customers_list]", new_customer_list)

    $("#customer-modal").modal("hide")
  }

  render() {
    const {
      is_editable,
      current_staff_name,
      reservation_staff_states: {
        pending_state,
        accepted_state,
      }
    } = this.props.reservation_properties

    const {
      pend,
      accept_customer,
      customer_cancel,
    } = this.props.i18n;

    const selected_customer = this.selected_customer()
    const approved = selected_customer && this.is_selected_customer_approved()

    return (
      <div className="modal fade" id="customer-modal" tabIndex="-1" role="dialog">
        <div className="modal-dialog" role="document">
          <div className="modal-content">
            <div className="modal-header">
              <button type="button" className="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">×</span></button>
              <h4 className="modal-title">
                <span className={`reservation-state ${selected_customer && selected_customer.state}`}>
                    {selected_customer && selected_customer.state === pending_state ? this.props.i18n.pending_state : this.props.i18n.accepted_state}
                 </span>
                 <span>{selected_customer && selected_customer.label}</span>
              </h4>
            </div>

            <div className="modal-body">
              <div dangerouslySetInnerHTML={{ __html: selected_customer && selected_customer.booking_price }} />
              { selected_customer && selected_customer.booking_from ? (
                <div dangerouslySetInnerHTML={{ __html: selected_customer && selected_customer.booking_from }} />
              ) :(
                <div className="booking-from reservation-info-row">
                  <i className="fa fa-clock-o"></i>
                  {current_staff_name}
                </div>
              )}
            </div>

            <div className="modal-footer">
              <dl>
                <dd>
                  <button
                    className={`btn ${approved ? "BTNgray" : "BTNtarco"} ${is_editable ? "" : "disabled"}`}
                    onClick={this.handleToggleCustomerState}>
                    {approved ? pend : accept_customer}
                  </button>
                  <button
                    className={`btn BTNorange ${is_editable ? "" : "disabled"}`}
                    onClick={this.handleCustomerDelete}>
                    {customer_cancel}
                  </button>
                </dd>
              </dl>
            </div>
          </div>
        </div>
      </div>
    )
  }
}

const CustomerFields = ({ fields, customer_field, customer_index, all_values, is_editable, reservation_form }) => {
  const handleCustomerItemClick = () => {
    const customer_id = _.get(all_values, `${customer_field}customer_id`)
    reservation_form.change("reservation_form[selected_customer_id]", customer_id)
     $("#customer-modal").modal("show")
  }

  const customer_state = _.get(all_values, `${customer_field}state`)

  // XXX: depending on ReservationCustomer::ACTIVE_STATES
  const hidden = (customer_state !== "accepted" && customer_state !== "pending")

  return (
    <dl
      key={`customer_field_${customer_index}`}
      className={`customer-option ${hidden ? "display-hidden" : ""}`}
      onClick={handleCustomerItemClick}>
      {["customer_id", "state", "booking_page_id", "booking_option_id",
        "booking_amount_cents", "booking_amount_currency", "tax_include", "booking_at", "details",
        "booking_price", "booking_from"].map((attr_name, attr_index) => (
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
      <CustomerPopup
        all_values={all_values}
        reservation_properties={reservation_properties}
        i18n={i18n}
        {...rest}
      />
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
          {...this.props}
          name={this.props.collection_name}
          component={CustomersList}
          list_height={this.state.listHeight}
        />
      </div>
    );
  }
}

export default ReservationCustomersList
