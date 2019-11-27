"use strict";

import React from "react";
import ProcessingBar from "../../../shared/processing_bar.js";

class ReservationsFilterReservationsList extends React.Component {
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
              data-controller="modal"
              data-modal-target="#dummyModal"
              data-action="click->modal#popup"
              data-modal-path={`/shops/${reservation.shopId}/reservations/${reservation.id}?from_filter=true`}
              className={reservation.state}
              >
              <dl key={reservation.id}>
                <dd className="date">
                  {reservation.year} <br />
                  {reservation.monthDate}
                </dd>
                <dd className="time">{reservation.startTime}<br />{reservation.endTime}</dd>
                <dd className="resSts"><span className={`reservation-state-item reservation-state ${reservation.state}`}></span></dd>
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
          <ProcessingBar processing={this.props.processing} processingMessage={this.props.processingMessage} />
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
            <div><span className="reservation-state-item reservation-state reserved"></span>予約</div>
            <div><span className="reservation-state-item reservation-state checkin"></span>チェックイン</div>
            <div><span className="reservation-state-item reservation-state checkout"></span>チェックアウト</div>
            <div><span className="reservation-state-item reservation-state pending"></span>承認待ち</div>
            <div><span className="reservation-state-item reservation-state canceled"></span>キャンセル</div>
          </div>
        </div>
      </div>
    );
  }
};

export default ReservationsFilterReservationsList;
