import React, { useState } from "react";
import { CustomerServices } from "user_bot/api";

export default function CustomersPermissions({props}) {
  const [customers, setCustomers] = useState(props.customers);

  return <div>
      {customers.map((customer) => (
        <div className="flex justify-evenly items-center" key={customer.id}>
          <div className="w-6-12">{customer.name}</div>
          <div className="w-6-12">
            {customer.reminder_permission ? <div className="btn btn-yellow btn-sm">ON</div> : (
              <a
              className="btn btn-tarco btn-sm"
              data-id={`customer-reminder-toggler-${customer.id}`}
              onClick={() => {
                CustomerServices.toggle_reminder_permission({ business_owner_id: props.business_owner_id, customer_id: customer.id })

                setCustomers(customers.map((c) => {
                  if (c.id === customer.id) {
                    return { ...c, reminder_permission: true };
                  }

                  return c;
                }))
            }}>
                {I18n.t("action.turn_on")}
              </a>
            )}
          </div>
        </div>
      ))}
  </div>;
}