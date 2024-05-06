"use strict";

import React from "react";

const BookingHeader = ({booking_page, is_done}) => {
  const {
    title,
    greeting,
    shop_logo_url,
    shop_name
  } = booking_page;

  return (
    <div className="header">
      <div className="header-title-part">
        <h1>
          { shop_logo_url ?  <img className="logo" src={shop_logo_url} /> : shop_name }
        </h1>
        <h2 className="page-title">{title}</h2>
      </div>

      {!is_done && <div className="greeting">{greeting}</div>}
    </div>
  )
}

export default BookingHeader;
