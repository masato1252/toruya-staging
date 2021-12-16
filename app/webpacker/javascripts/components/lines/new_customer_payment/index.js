"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';

export const NewCustomerPayment = ({props}) => {
  return (
    <div className="done-view">
      <h3 className="title">
        {I18n.t("common.pay_the_payment")}
      </h3>
    </div>
  )
}

export default NewCustomerPayment;
