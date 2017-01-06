"use strict";

UI.define("Customers.CustomerReservationsView", function() {
  var CustomerReservationsView = React.createClass({
    getInitialState: function() {
      this.reservactionBehaviors = {
        "checked_in": [{ label: "CHECK OUT", action: "check_out", btn_color: "BTNyellow" }],
        "reserved": [{ label: this.props.checkInBtn, action: "check_in", btn_color: "BTNyellow" },
                     { label: this.props.pendBtn, action: "pend", btn_color: "BTNgray" }],
        "noshow": [{ label: this.props.checkInBtn, action: "check_in", btn_color: "BTNyellow" },
                   { label: this.props.pendBtn, action: "pend", btn_color: "BTNgray" }],
        "pending": [{ label: this.props.acceptBtn, action: "accept", btn_color: "BTNtarco" }],
        "checked_out": [{ label: this.props.pendBtn, action: "pend" }],
      };

      return ({
        reservations: []
      });
    },

    componentDidMount: function() {
      this.fetchReservations();
    },

    fetchReservations: function() {
      var _this = this;

      if (this.props.customer.id) {
        this.props.switchProcessing(function() {
          $.ajax({
            type: "GET",
            url: _this.props.customerReservationsPath,
            data: { id: _this.props.customer.id },
            dataType: "JSON"
          }).success(function(result) {
            _this.setState({ reservations: result["reservations"] });
          }).always(function() {
            _this.props.switchProcessing();
          });
        });
      }
    },

    handleReservationStateChange: function() {

    },

    renderReservations: function() {
      var previousYear;
      var _this = this;
      var reservationsView = this.state.reservations.map(function(reservation, i) {
        var divider = null;
        if (reservation.year != previousYear) {
          previousYear = reservation.year;
          divider = (
            <a href="#" className="year">
              <dl>
                <dd className="date">{reservation.year}</dd>
              </dl>
            </a>
          )
        }
        return (
          <div key={`reservation-${reservation.id}`} id={`reservation-${reservation.id}`}>
            {divider}
            <a href="#"
              className={reservation.state}
              data-toggle="modal"
              data-target={`#reservationModal${reservation.id}`}
              >
              <dl>
                <dd className="date">{reservation.date}</dd>
                <dd className="time">{reservation.startTime}<br />{reservation.endTime}</dd>
                <dd><span className={`reservation-state ${reservation.state}`}></span></dd>
                <dd className="menu">{reservation.menu}</dd>
                <dd className="shop">{reservation.shop}</dd>
              </dl>
            </a>
            <div className="modal fade" id={`reservationModal${reservation.id}`} tabindex="-1" role="dialog" aria-labelledby="myModalLabel">
              <div className="modal-dialog" role="document">
                <div className="modal-content">
                  <div className="modal-header">
                    <button type="button" className="close" data-dismiss="modal" aria-label="Close">
                      <span aria-hidden="true">&times;</span>
                    </button>
                    <h4 className="modal-title" id="myModalLabel">
                      {reservation.date}
                      {reservation.startTime} 〜 {reservation.endTime}
                    </h4>
                  </div>
                  <div className="modal-body">
                    <div className="reservation-menu">
                      {reservation.menu}
                    </div>
                    <div>
                      {reservation.staffs}
                    </div>
                  </div>
                  <div className="modal-footer">
                    <dl>
                      {this.reservactionBehaviors[reservation.state].map(function(behavior) {
                        return (
                          <dd key={`reseravtion-${reservation.id}-action-${behavior["action"]}`}>
                            <a
                              href={`${_this.props.stateCustomerReservationsPath}?reservation_id=${reservation.id}&reservation_action=${behavior["action"]}&shop_id=${_this.props.shop.id}&id=${_this.props.customer.id}`}
                              className={`btn ${behavior["btn_color"]}`}
                              data-method="put" >
                              {behavior["label"]}
                            </a>
                          </dd>
                        );
                      })}
                      <dd>
                        <a
                          href={`${_this.props.editCustomerReservationsPath}?shop_id=${reservation.shopId}&from_shop_id=${_this.props.shop.id}&from_customer_id=${_this.props.customer.id}&reservation_id=${reservation.id}`}
                          className="btn BTNgray">
                          {this.props.editBtn}
                        </a>
                      </dd>
                      {
                        reservation.state != "checked_out" ? (
                          <dd>
                          <a
                            href={`${_this.props.stateCustomerReservationsPath}?reservation_id=${reservation.id}&reservation_action=destroy&shop_id=${_this.props.shop.id}&id=${_this.props.customer.id}`}
                            className="btn BTNorange"
                            data-method="put"
                            >{this.props.cancelBtn}</a>
                          </dd>
                        ) : null
                      }
                    </dl>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )
      }.bind(this));

      return reservationsView
    },

    render: function() {
      return (
        <div id="customerInfo" className="contBody">
          <div id="basic">
            <dl>
              <dt>
                <ul>
                  {this.props.customer.groupName ?
                    <li>{this.props.customer.groupName}</li> : null
                  }
                  {
                    this.props.customer.rank ?
                      <li className={this.props.customer.rank.key}>{this.props.customer.rank.name}</li> : null
                  }
                </ul>
              </dt>
              <dd>
                <ul className="kana">
                  <li>{this.props.customer.phoneticLastName} {this.props.customer.phoneticFirstName}</li>
                </ul>
                <ul><li>{this.props.customer.lastName} {this.props.customer.firstName}</li></ul>
              </dd>
              <dd>
                {
                  this.props.customer.primaryPhone && this.props.customer.primaryPhone.value ? (
                    <a href={`tel:${this.props.customer.primaryPhone.value}`} className="BTNtarco">
                      <i className={`fa fa-phone fa-2x`}aria-hidden="true" title="call"></i>
                    </a>
                  ) : null
                }
                {
                  this.props.customer.primaryEmail && this.props.customer.primaryEmail.value ? (
                    <a href={`mail:${this.props.customer.primaryEmail.value.address}`} className="BTNtarco">
                      <i className="fa fa-envelope fa-2x" aria-hidden="true" title="mail"></i>
                    </a>
                  ) : null
                }
              </dd>
            </dl>
          </div>

          <div id="tabs" className="tabs">
            <a href="#" className="here">利用履歴</a>
            <a href="#" onClick={this.props.switchReservationMode}>顧客情報</a>
          </div>

          <div id="resList" className="tabBody" style={{height: "425px"}}>
            <dl className="tableTTL">
              <dt className="date">ご利用日</dt>
              <dt className="time">開始<br />終了</dt>
              <dt className="reservation-states"></dt>
              <dt className="menu">メニュー</dt>
              <dt className="shop">店舗</dt>
              </dl>

            <div id="record">
              {this.renderReservations()}
            </div>
          </div>
        </div>
      );
    }
  });

  return CustomerReservationsView;
});
