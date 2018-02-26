"use strict";

import React from "react";
import "../../shared/processing_bar.js";

UI.define("Reservations.Filter.ReservationsList", function() {
  return class ReservationsList extends React.Component {
    renderReservationModals = () => {
      var _this = this;

      var reservationModalsView = (this.props.reservations || []).map(function(reservation, i) {
        return (
          <div key={`reservation-modal-${reservation.id}`} id={`reservation-modal-${reservation.id}`}>
            <div className="modal fade" id={`reservationModal${reservation.id}`} tabIndex="-1" role="dialog" aria-labelledby="myModalLabel">
              <div className="modal-dialog" role="document">
                <div className="modal-content">
                  <div className="modal-header">
                    <button type="button" className="close" data-dismiss="modal" aria-label="Close">
                      <span aria-hidden="true">&times;</span>
                    </button>
                    <h4 className="modal-title" id="myModalLabel">
                      <a href={`/shops/${reservation.shopId}/reservations/${reservation.date}`}>
                        {reservation.monthDate}
                      </a>
                      <span>
                        {reservation.startTime} 〜 {reservation.endTime}
                      </span>
                    </h4>
                  </div>
                  <div className="modal-body">
                  <div>
                    {reservation.customers.map(function(customer) {
                      return (
                        <a
                          key={`reservation-${reservation.id}-customer-${customer.id}`}
                          className="customer-link"
                          href={`/shops/${reservation.shopId}/customers?customer_id=${customer.id}`}>
                          {customer.name}
                        </a>
                      )
                    })
                    }
                    </div>
                    <div className="reservation-menu">
                      {reservation.menu}
                    </div>
                    <div>
                      {reservation.staffs}
                    </div>
                    {
                      reservation.withWarnings ? (
                        <div className="warning">
                          <i className="fa fa-check-circle" aria-hidden="true"></i>
                          {this.props.withWarningsMessage}
                        </div>
                      ) : null
                    }
                    {
                      reservation.deletedStaffs ? (
                        <div className="danger">
                          <i className="fa fa-exclamation-circle" aria-hidden="true"></i>
                          {reservation.deletedStaffs}
                        </div>
                      ) : null
                    }
                    <div dangerouslySetInnerHTML={{ __html: reservation.memo }} />
                  </div>
                </div>
              </div>
            </div>
          </div>
        )
      }.bind(this));

      return reservationModalsView
    };

    renderReservationsList = () => {
      if (!this.props.reservations) {
        return <div></div>
      }
      else if (this.props.reservations.length === 0) {
        return <div className="empty-content">{this.props.emptyContent}</div>
      }
      else {
        return (
          this.props.reservations.map(function(reservation) {
            return (
              <a href="#"
                className={reservation.state}
                data-toggle="modal"
                data-target={`#reservationModal${reservation.id}`}
                key={`reservation-${reservation.id}`}
                >
                <dl key={reservation.id}>
                  <dd className="date">
                    {reservation.year} <br />
                    {reservation.monthDate}
                  </dd>
                  <dd className="time">{reservation.startTime}<br />{reservation.endTime}</dd>
                  <dd className="resSts"><span className={`reservation-state ${reservation.state}`}></span></dd>
                  <dd className="menu">{reservation.menu}</dd>
                  <dd className="customer">{reservation.customersSentence}</dd>
                  <dd className="shop">{reservation.shop}</dd>
                </dl>
              </a>
            )
          })
        );
      }
    };

    render() {
      return (
        <div className="contBody">
          <div id="resList">
            <UI.ProcessingBar processing={this.props.processing} processingMessage={this.props.processingMessage} />
            <dl className="tableTTL">
              <dt className="date">予約日</dt>
              <dt className="time">開始<br />終了</dt>
              <dt className="resSts"></dt>
              <dt className="menu">メニュー</dt>
              <dt className="customer">顧客台帳</dt>
              <dt className="shop">店舗</dt>
            </dl>
            <div id="record">
              {this.renderReservationsList()}
            </div>
            <div className="status-list">
              <div><span className="reservation-state reserved"></span>予約</div>
              <div><span className="reservation-state checkin"></span>チェックイン</div>
              <div><span className="reservation-state checkout"></span>チェックアウト</div>
              <div><span className="reservation-state noshow"></span>未来店</div>
              <div><span className="reservation-state pending"></span>承認待ち</div>
              <div><span className="reservation-state canceled"></span>キャンセル</div>
            </div>
          </div>
          {this.renderReservationModals()}
        </div>
      );
    }
  };
});

export default UI.Reservations.Filter.ReservationsList;
