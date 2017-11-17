"use strict";

import React from "react";
import "../shared/datepicker_field.js";

var createReactClass = require('create-react-class');

UI.define("Reservation.DatetimeFields", function() {
  var DatetimeFields = createReactClass({
    getInitialState: function() {
      return ({
        start_time_date_part: this.props.startTimeDatePart,
        start_time_time_part: this.props.startTimeTimePart,
        end_time_time_part: this.props.endTimeTimePart
      });
    },

    _handleChange: function(event) {
      this.setState({[event.target.dataset.name]: event.target.value})
    },

    render: function() {
      return (
        <div>
          <input type="hidden" name="staff_id" value={this.props.staffId} />
          <input
            type="hidden"
            name="custom_schedules[][open]"
            defaultValue={this.props.open}
            />
          <dt className="date">
            <UI.Common.DatepickerField
              date={this.state.start_time_date_part}
              name="custom_schedules[][start_time_date_part]"
              dataName="start_time_date_part"
              handleChange={this._handleChange}
              calendarfieldPrefix={this.props.calendarfieldPrefix}
            />
          </dt>
          <dd className="startTime">
            <input
              type="time"
              name="custom_schedules[][start_time_time_part]"
              data-name="start_time_time_part"
              value={this.state.start_time_time_part}
              size="20"
              onChange={this._handleChange} />
          </dd>
          <dd className="timeTo"> ~ </dd>
          <dd className="endTime">
            <input
              type="time"
              name="custom_schedules[][end_time_time_part]"
              data-name="end_time_time_part"
              value={this.state.end_time_time_part}
              size="20"
              onChange={this._handleChange} />
          </dd>
        </div>
      )
    }
  });
  return DatetimeFields;
})

export default UI.Reservation.DatetimeFields;
