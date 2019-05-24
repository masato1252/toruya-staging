"use strict";

import React from "react";
import { Form } from "react-final-form";

class BookingReservationForm extends React.Component {
  constructor(props) {
    super(props);
  };

  renderBookingHeader = (values) => {
    return (
      <div>
        <img className="logo" src={this.props.shop_logo_url} />
      </div>
    )
  }

  render() {
    return <div>Shop</div>

    return (
      <Form
        action={this.props.path.save}
        initialValues={{ booking_page: { ...transformValues(this.props.booking_page) }}}
        onSubmit={this.onSubmit}
        render={({ handleSubmit, submitting, values }) => {
          return (
            <form
              action={this.props.path.save}
              className="booking-page"
              onSubmit={handleSubmit}
              acceptCharset="UTF-8"
              method="post">
              <input name="utf8" type="hidden" value="✓" />
              <input type="hidden" name="authenticity_token" value={this.props.form_authenticity_token} />
              {this.renderBookingHeader(values)}

              <input
                type="submit"
                name="commit"
                value={this.props.i18n.save}
                className="BTNyellow"
                data-disable-with={this.props.i18n.save}
                disabled={submitting}
              />
            </form>
          )
        }}
      />
    )
  }
}

export default BookingReservationForm;
