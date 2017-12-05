"use strict";

import React from "react";
import "../../shared/processing_bar.js";

UI.define("Reservations.Filter.ReservationsList", function() {
  return class ReservationsList extends React.Component {
    renderReservationsList = () => {
      return (
        this.props.reservations.map(function(reservation) {
          return (
            <dl key={reservation.id}>
              <dd className="status"></dd>
              <dd className="time">{reservation.start_time}</dd>
              <dd className="customer">{reservation.menu}</dd>
            </dl>
          )
        })
      );
    };

    render() {
      return (
        <div id="resList" className="contBody">
          <UI.ProcessingBar processing={this.props.processing} processingMessage={this.props.processingMessage} />
          <dl className="tableTTL">
            <dt className="status">&nbsp;</dt>
            <dt className="customer">顧客氏名</dt>
            <dt className="address">住所</dt>
            <dt className="group">顧客台帳</dt>
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
      );
    }
  };
});

export default UI.Reservations.Filter.ReservationsList;
