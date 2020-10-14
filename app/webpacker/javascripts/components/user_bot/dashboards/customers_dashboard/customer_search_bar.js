"use strict";

import React, { useContext, useRef } from "react";
import { InputWithEnter } from "shared/components";
import { GlobalContext } from "context/user_bots/customers_dashboard/global_state";

const CustomerSearchBar = ()  => {
  const searchInput = useRef()
  const { searchCustomers } = useContext(GlobalContext)

  const onHandleEnter = () => {
    console.log(searchInput.current.value)

    if (searchInput.current.value) {
      searchCustomers(searchInput.current.value)
      searchInput.current.blur()
      searchInput.current.value = ""
    }
  }

  return (
    <>
      <div className="input-group">
        <span className="input-group-addon" id="basic-addon1">
          <i className="fa fa-search search-symbol" aria-hidden="true"></i>
        </span>
        <InputWithEnter
          ref={searchInput}
          className="form-control"
          placeholder="Search"
          onHandleEnter={onHandleEnter}
        />
      </div>
    </>
  )
}

export default CustomerSearchBar;
