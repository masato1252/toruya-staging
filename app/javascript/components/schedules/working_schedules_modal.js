"use strict";

import React from "react";

import "../reservations/datetime_fields.js"

UI.define("WorkingSchedulesModal", function() {
  return class WorkingSchedulesModal extends React.Component {
    constructor(props) {
      super(props);
    };

    render() {
      return (
        <div className="modal fade" id="working-date-modal" tabIndex="-1" role="dialog">
          <div className="modal-dialog" role="document">
            <div className="modal-content">
              <div className="modal-header">
                <button type="button" className="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">×</span></button>
                <h4 className="modal-title">
                  {this.props.staff.name}の出勤日を追加
                </h4>
              </div>

              <form
                id="customer-edit-form"
                acceptCharset="UTF-8"
                action={this.props.customSchedulesPath}
                method="post">
                <input name="authenticity_token" type="hidden" value={this.props.formAuthenticityToken} />
                <div className="modal-body">
                  <dl id="addWorkDay">
                    <UI.Reservation.DatetimeFields
                      staffId={this.props.staff.id}
                      open={this.props.open}
                      startTimeDatePart={this.props.startTimeDatePart}
                      startTimeTimePart={this.props.startTimeTimePart}
                      endTimeTimePart={this.props.endTimeTimePart}
                      calendarfieldPrefix="temp_working_schedules"
                    />
                    <div className="shops-list">
                      {this.props.shops.map((shop) => {
                        return (
                          <div className="shop-cell" key={`shop-${shop.id}`}>
                          <input
                            type="checkbox"
                            name="shop_ids[]"
                            id={`shop-${shop.id}-schedule`}
                            defaultValue={shop.id}
                            defaultChecked={shop.id === this.props.shop.id}
                            />
                            <label htmlFor={`shop-${shop.id}-schedule`}>{shop.name}</label>
                          </div>
                        )
                      })}
                    </div>
                  </dl>
                </div>
                <div className="modal-footer">
                  <dl>
                    <dd></dd>
                    <dd>
                      <input type="submit" name="commit" value="保存" className="btn BTNyellow" data-disable-with="保存" />
                    </dd>
                    <dd></dd>
                  </dl>
                </div>
              </form>
            </div>
          </div>
        </div>
      );
    }
  };
});

export default UI.WorkingSchedulesModal;
