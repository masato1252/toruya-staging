"use strict";

import React from "react";
import Autolinker from "autolinker";

const BookingHeader = ({booking_page, is_done}) => {
  const {
    title,
    greeting,
    shop_logo_url,
    shop_name
  } = booking_page;

  // Function to render greeting with clickable URLs using Autolinker
  const renderGreetingWithLinks = (text) => {
    if (!text) return null;

    const linkedText = Autolinker.link(text, {
      urls: true,
      email: false,
      phone: false,
      newWindow: true,
      className: '',
      style: 'color: inherit; text-decoration: underline;'
    });

    return <div dangerouslySetInnerHTML={{__html: linkedText}} />;
  };

  return (
    <div className="header">
      <div className="header-title-part">
        <h1>
          { shop_logo_url ?  <img className="logo" src={shop_logo_url} /> : shop_name }
        </h1>
        <h2 className="page-title">{title}</h2>
      </div>

      {!is_done && <div className="greeting">{renderGreetingWithLinks(greeting)}</div>}
    </div>
  )
}

export default BookingHeader;
