"use strict";

import React from "react";
import CustomersDashboard from "./customers_dashboard";

const CustomerFeaturesTab = ({selected, customer, selectCustomerView, customerDetailsReadable, i18n}) => {
  if (selected === CustomersDashboard.customerView.customer_info) {
    return (
      <div id="tabs" className="tabs">
        <a href="#" className="" onClick={() => selectCustomerView(CustomersDashboard.customerView.customer_reservations)}>
          {i18n.customerReservationsTab}
        </a>
        {customer.socialUserId &&
          <a href="#" className="" onClick={() => selectCustomerView(CustomersDashboard.customerView.customer_messages)}>
            Line
          </a>
        }
        <a href="#" className="here">
          {i18n.customerInfoTab}
        </a>
      </div>
    )
  }
  else if (selected === CustomersDashboard.customerView.customer_reservations) {
    return (
      <div id="tabs" className="tabs">
        <a href="#" className="here">
          {i18n.customerReservationsTab}
        </a>
        {customer.socialUserId &&
          <a href="#" className="" onClick={() => selectCustomerView(CustomersDashboard.customerView.customer_messages)}>
            Line
          </a>
        }
        {customerDetailsReadable &&
          <a href="#" onClick={() => selectCustomerView(CustomersDashboard.customerView.customer_info)}>
            {i18n.customerInfoTab}
          </a>
        }
      </div>
    )
  }
  else if (selected === CustomersDashboard.customerView.customer_messages) {
    return (
      <div id="tabs" className="tabs">
        <a href="#" className="" onClick={() => selectCustomerView(CustomersDashboard.customerView.customer_reservations)}>
          {i18n.customerReservationsTab}
        </a>
        {customer.socialUserId &&
          <a href="#" className="here">
            Line
          </a>
        }
        {customerDetailsReadable &&
          <a href="#" onClick={() => selectCustomerView(CustomersDashboard.customerView.customer_info)}>
            {i18n.customerInfoTab}
          </a>
        }
      </div>
    )
  }
}

export default CustomerFeaturesTab;
