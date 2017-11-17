"use strict";

import React from "react";
import "./custom_schedule_fields.js";
import "../shared/datepicker_field.js";

var createReactClass = require("create-react-class");

UI.define("CustomSchedules", function() {
  var CustomSchedules = createReactClass({
    getDefaultProps: function() {
      return {
        open: false
      };
    },

    getInitialState: function() {
      return ({
        start_time_date_part: "",
        start_time_time_part: "",
        end_time_time_part: "",
        reason: "",
        customSchedules: this.props.customSchedules
      });
    },

    _handleChange: function(event) {
      this.setState({[event.target.name]: event.target.value})
    },

    _isValidCustomSchedule: function() {
      return (this.state.start_time_date_part && this.state.start_time_time_part && this.state.end_time_time_part);
    },

    _handleAddRow: function(event) {
      event.preventDefault();

      if (!this._isValidCustomSchedule()) { return; }

      var customSchedules = this.state.customSchedules.slice(0)
      customSchedules.push({startTimeDatePart: this.state.start_time_date_part,
                            startTimeTimePart: this.state.start_time_time_part,
                            endTimeTimePart: this.state.end_time_time_part,
                            reason: this.state.reason})
      this.setState({
        customSchedules: customSchedules,
        start_time_date_part: "",
        start_time_time_part: "",
        end_time_time_part: "",
        reason: ""
      })
    },

    render: function() {
      return (
      <div id="tempWork">
        <dl>
          <dt className="date">
            <UI.Common.DatepickerField
              date={this.state.start_time_date_part}
              dataName="start_time_date_part"
              handleChange={this._handleChange}
              calendarfieldPrefix={this.props.calendarfieldPrefix}
            />
          </dt>
          <dd className="startTime">
            <input type="time" name="start_time_time_part" value={this.state.start_time_time_part} size="20" onChange={this._handleChange} />
          </dd><dd className="endTime">
            <input type="time" name="end_time_time_part" value={this.state.end_time_time_part} size="20" onChange={this._handleChange} />
            </dd>
          {this.props.open || this.props.fromStaff ? null : (
            <dd className="closeReason">
              <input type="text" name="reason" placeholder={this.props.closingReason} value={this.state.reason} size="20" onChange={this._handleChange} />
            </dd>
          )}
          <dd className="add function">
            <a href="#" className={`BTNtarco ${this._isValidCustomSchedule() ? "" : "disabled"}`} onClick={this._handleAddRow}>{this.props.newClosingBtn}</a>
          </dd>
          </dl>
         {this.state.customSchedules.map(function(schedule, i) {
           return <UI.CustomScheduleFields key={`${schedule.id}-${i}`}
             schedule={schedule}
             shopId={this.props.shopId}
             deleteBtn={this.props.deleteBtn}
             open={this.props.open}
             calendarfieldPrefix={`${this.props.calendarfieldPrefix}-${i + 1}`}
             closingReason={this.props.closingReason}
             fromStaff={this.props.fromStaff}
           />
         }.bind(this))}
      </div>
      );
    }
  });

  return CustomSchedules;
});

export default UI.CustomSchedules;
