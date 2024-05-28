"use strict";

import React from "react";

import { TicketPriceDesc } from "shared/components";

const BookingPagePreview = ({shop, booking_page, booking_option, ticket_quota, i18n, edit_option, edit_price}) => {
  return (
    <div className="booking-page-preview">
      <div className="header">
        <div className="header-title-part">
          <h1>
            {shop.logoUrl ?  <img className="logo" src={shop.logoUrl} /> : shop.shortName}
            <span className="preview-mark">
              {i18n.preview}
            </span>
          </h1>
          <h2 className="page-title">{booking_page.title}</h2>
        </div>
          <div className="greeting">{booking_page.greeting}</div>
      </div>

      <div className="booking-option-field">
        <div className="booking-option-info">
          <div className="booking-option-name">
            <b>{booking_option.name}</b>
            <span className="btn btn-yellow edit-mark" onClick={edit_option}>
              <i className="fa fa-pencil-alt"></i>
              {i18n.edit}
            </span>
          </div>
          <div>{i18n.booking_option_required_time}{booking_option.minutes}{i18n.minute}</div>
        </div>
        <div className="booking-option-row">
          <span>{booking_option.price}
            {ticket_quota && ticket_quota > 1 && (
              <>
                <i className="fa fa-ticket-alt text-gray-500"></i> <TicketPriceDesc amount={booking_option.price_amount} ticket_quota={ticket_quota} />
              </>
            )}
          </span>

          {edit_price != undefined && (
            <span className="btn btn-yellow edit-mark" onClick={edit_price}>
              <i className="fa fa-pencil-alt"></i>
              {i18n.edit}
            </span>
          )}
        </div>
      </div>
    </div>
  )
}

export default BookingPagePreview
