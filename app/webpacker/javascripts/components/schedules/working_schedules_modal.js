"use strict";

import React from "react";
import axios from "axios";

import ReservationDatetimeFields from "../reservations/datetime_fields.js"

class WorkingSchedulesModal extends React.Component {
  constructor(props) {
    super(props);
  };

  handleSubmit = (event) => {
    if (this.props.remote) {
      let _this = this;

      event.preventDefault();
      var valuesToSubmit = $(this.working_schedules_form).serialize();

      axios({
        method: "POST",
        url: this.props.customSchedulesPath, //sumbits it to the given url of the form
        data: valuesToSubmit,
        responseType: "json"
      }).then(function() {
        _this.props.callback();
      }).then(function() {
        $("#working-date-modal").modal("hide");
      });
    } else {
      setTimeout(function() {
        $(this.working_schedules_form).submit();
      }, 0);
    }
  }

  render() {
    return (
      <div className="modal fade" id="working-date-modal" tabIndex="-1" role="dialog">
        <div className="modal-dialog" role="document">
          <div className="modal-content">
            <div className="modal-header">
              <button type="button" className="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">×</span></button>
              <h4 className="modal-title">
                {this.props.staff && (this.props.staff.name || this.props.staff.label)}の出勤日を追加
              </h4>
            </div>

            <form
              acceptCharset="UTF-8"
              method="post"
              ref={(c) => this.working_schedules_form = c}
              action={this.props.customSchedulesPath}
              >
              <input name="authenticity_token" type="hidden" value={this.props.formAuthenticityToken} />
              <div className="modal-body">
                <dl id="addWorkDay">
                  <ReservationDatetimeFields
                    staffId={this.props.staffId || this.props.staff.id || this.props.staff.value}
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
                    <button type="submit" id="BTNsave" className="btn BTNyellow" onClick={this.handleSubmit}>
                      保存
                    </button>
                  </dd>
                </dl>
              </div>
            </form>
          </div>
        </div>
      </div>
    );
  }
};

export default WorkingSchedulesModal;
