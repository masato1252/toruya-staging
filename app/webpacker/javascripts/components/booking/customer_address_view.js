"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';

import AddressView from "shared/address_view";

const CustomerAddressView = ({address, handleAddressCallback}) => {
  return (
    <>
      <h3 className="centerize title">
        {I18n.t("common.customer_address_view_title")}
      </h3>
      <AddressView handleSubmitCallback={handleAddressCallback} address_details={address} />
    </>
  )
}

export default CustomerAddressView;
