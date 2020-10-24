"use strict";

import React, { useRef } from "react";
import { InputWithEnter } from "shared/components";
import { useGlobalContext } from "context/user_bots/customers_dashboard/global_state";

const CustomerSearchBar = ()  => {
  const searchInput = useRef()
  const { searchCustomers, props } = useGlobalContext()

  const onHandleEnter = () => {
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
        <form action="">
          <InputWithEnter
            type="search"
            ref={searchInput}
            className="form-control"
            placeholder={props.i18n.search_placeholder}
            name="search"
            id="search"
            onHandleEnter={onHandleEnter}
          />
        </form>
      </div>
    </>
  )
}

export default CustomerSearchBar;
