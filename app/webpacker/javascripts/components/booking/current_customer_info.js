"use strict";

import React from "react";

const CurrentCustomerInfo = ({booking_reservation_form_values, i18n, isCustomerTrusted, not_me_callback}) => {
  const { customer_last_name, customer_first_name, found_customer } = booking_reservation_form_values;
  const { simple_address, last_name, first_name } = booking_reservation_form_values.customer_info;
  const { not_me, edit_info, of, sir, thanks_for_come_back } = i18n

  if (!found_customer) return <></>;

  if (found_customer) {
    return (
      <div className="customer-found">
        <div>
          {thanks_for_come_back}
        </div>
        <div>
          {simple_address && simple_address.trim().length > 0 && (
            <div className="simple-address">
              {simple_address}{simple_address && of}
            </div>
          )}
          <div className="customer-full-name">
            {customer_last_name || last_name} {customer_first_name || first_name} {sir}
          </div>
        </div>
        <div className="edit-customer-info">
          <a href="#" onClick={() => $("#customer-info-modal").modal("show")}>{edit_info}</a>
        </div>
        <div className="not-me">
          <a href="#" onClick={not_me_callback}>
            {customer_last_name || last_name} {customer_first_name || first_name} {not_me}
          </a>
        </div>
      </div>
    )
  }
  else {
    return (
      <div className="customer-found">
        <div className="customer-full-name">
          {customer_last_name} {customer_first_name} {sir}
        </div>
      </div>
    )
  }
}

export default CurrentCustomerInfo
