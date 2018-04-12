"use strict";

import React from "react";
import "../shared/datepicker_field.js";

UI.define("Reservation.DatetimeFields", function() {
  return class DatetimeFields extends React.Component {
    constructor(props) {
      super(props);

      this.state = {
        startTimeDatePart: this.props.startTimeDatePart,
        startTimeTimePart: this.props.startTimeTimePart,
        endTimeTimePart: this.props.endTimeTimePart
      }
    };

    componentWillReceiveProps(nextProps) {
      // You don't have to do this check first, but it can help prevent an unneeded render
      if (
            nextProps.startTimeDatePart !== this.state.startTimeDatePart ||
            nextProps.startTimeTimePart !== this.state.startTimeTimePart ||
            nextProps.endTimeTimePart !== this.state.endTimeTimePart
         ) {
       this.setState({
         startTimeDatePart: nextProps.startTimeDatePart,
         startTimeTimePart: nextProps.startTimeTimePart,
         endTimeTimePart: nextProps.endTimeTimePart
       });
      }
    }

    _handleChange = (event) => {
      this.setState({[event.target.dataset.name]: event.target.value})
    };

    render() {
      return (
        <div className="datetime-field">
          <input type="hidden" name="staff_id" value={this.props.staffId} />
          <input
            type="hidden"
            name="custom_schedules[][open]"
            defaultValue={this.props.open}
            />
          <dt className="date">
            <UI.Common.DatepickerField
              date={this.state.startTimeDatePart}
              name="custom_schedules[][start_time_date_part]"
              dataName="startTimeDatePart"
              handleChange={this._handleChange}
              calendarfieldPrefix={this.props.calendarfieldPrefix}
            />
          </dt>
          <dd className="startTime">
            <input
              type="time"
              name="custom_schedules[][start_time_time_part]"
              data-name="startTimeTimePart"
              value={this.state.startTimeTimePart}
              size="20"
              onChange={this._handleChange} />
          </dd>
          <dd className="timeTo"> ~ </dd>
          <dd className="endTime">
            <input
              type="time"
              name="custom_schedules[][end_time_time_part]"
              data-name="endTimeTimePart"
              value={this.state.endTimeTimePart}
              size="20"
              onChange={this._handleChange} />
          </dd>
        </div>
      )
    }
  };
})

export default UI.Reservation.DatetimeFields;
