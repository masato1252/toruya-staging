import React from "react";
import { Field } from "react-final-form";
import { FieldArray } from 'react-final-form-arrays';
import _ from "lodash";

import { setProperListHeight } from "../../../libraries/helper";

const CustomerFields = ({ fields, customer_field, customer_index, all_values }) => {
  return (
    <dl key={`customer_field_${customer_index}`} className={`customer-option`}>
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
        <span className={`customer-level-symbol ${_.get(all_values, `${customer_field}rank`)}`}>
          <i className="fa fa-address-card"></i>
        </span>
      </dd>
      <dt>
        <p>{_.get(all_values, `${customer_field}label`)}</p>
        <p className="place">{_.get(all_values, `${customer_field}address`)}</p>
      </dt>
      <dd onClick={(event) => {
        event.preventDefault();
        fields.remove(customer_index)
        }}>
        <span className={`BTNyellow customer-remove-symbol glyphicon glyphicon-remove}`}>
          <i className="fa fa-times" aria-hidden="true"></i>
        </span>
      </dd>
    </dl>
  )
}
const CustomersList = ({ fields, ...rest }) => {
  return (
    <div>
      {fields.map((field, index) => {
        return (
          <CustomerFields
            key={`${field}${index}`}
            fields={fields}
            customer_field={field}
            customer_index={index}
            {...rest}
          />
        )
      })}
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
      <div
        id="customerList"
        style={{height: this.state.listHeight}}
      >
        <FieldArray
          name={this.props.collection_name}
          collection_name={this.props.collection_name}
          component={CustomersList}
          all_values={this.props.all_values}
        />
      </div>
    );
  }
}

export default ReservationCustomersList
