"use strict";

import React from "react";

class CustomerReservationsView extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      reservations: []
    }
  };

  componentDidMount = () => {
    this.fetchReservations();
  };

  fetchReservations = () => {
    var _this = this;

    if (this.props.customer.id) {
      this.props.switchProcessing(function() {
        $.ajax({
          type: "GET",
          url: _this.props.customerReservationsPath,
          data: { id: _this.props.customer.id, shop_id: _this.props.shop.id},
          dataType: "JSON"
        }).success(function(result) {
          _this.setState({ reservations: result["reservations"] });
        }).always(function() {
          _this.props.forceStopProcessing();
        });
      });
    }
  };

  renderReservations = () => {
    var previousYear;
    var _this = this;
    var divider;

    var reservationsView = this.state.reservations.map(function(reservation, i) {
      divider = null;
      if (reservation.year != previousYear) {
        previousYear = reservation.year;
        divider = (
          <dl className="year">
            <dd>{reservation.year}</dd>
          </dl>
        )
      }
      return (
        <div key={`reservation-${reservation.id}`} id={`reservation-${reservation.id}`}>
          {divider}
          <a
            href="#"
            data-controller="modal"
            data-modal-target="#dummyModal"
            data-action="click->modal#popup"
            data-modal-path={`/shops/${reservation.shopId}/reservations/${reservation.id}?from_customer='true'`}
            className={reservation.state}
            >
            <dl>
              <dd className="date">{reservation.monthDate}</dd>
              <dd className="time">{reservation.startTime}<br />{reservation.endTime}</dd>
              <dd className="resSts"><span className={`reservation-state ${reservation.state}`}></span></dd>
              <dd className="menu">{reservation.menu}</dd>
              <dd className="shop">{reservation.shop}</dd>
              {
                reservation.withWarnings ? (
                  <dd className="status warning"><i className="fa fa-check-circle" aria-hidden="true"></i></dd>
                ) : null
              }
              {
                reservation.deletedStaffs ? (
                  <dd className="status danger"><i className="fa fa-exclamation-circle" aria-hidden="true"></i></dd>
                ) : null
              }
            </dl>
          </a>
        </div>
      )
    }.bind(this));

    return reservationsView
  };

  render() {
    return (
      <div className="contBody">
        <div id="customerInfo">
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
              <dt className="resSts"></dt>
              <dt className="menu">メニュー</dt>
              <dt className="shop">店舗</dt>
              </dl>

            <div id="record">
              {this.renderReservations()}
            </div>
          </div>
        </div>
      </div>
    );
  }
};

export default CustomerReservationsView;
