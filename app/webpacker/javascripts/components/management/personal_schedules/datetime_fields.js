"use strict";

import React from "react";
import CommonDatepickerField from "shared/datepicker_field.js";
import I18n from 'i18n-js/index.js.erb';

class PersonalScheduleDatetimeFields extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      startTimeDatePart: this.props.startTimeDatePart,
      startTimeTimePart: this.props.startTimeTimePart,
      endTimeDatePart: this.props.endTimeDatePart,
      endTimeTimePart: this.props.endTimeTimePart
    }
  };

  componentWillReceiveProps(nextProps) {
    // You don't have to do this check first, but it can help prevent an unneeded render
    if (
          nextProps.startTimeDatePart !== this.state.startTimeDatePart ||
          nextProps.startTimeTimePart !== this.state.startTimeTimePart ||
          nextProps.endTimeDatePart !== this.state.endTimeDatePart ||
          nextProps.endTimeTimePart !== this.state.endTimeTimePart
       ) {
     this.setState({
       startTimeDatePart: nextProps.startTimeDatePart,
       startTimeTimePart: nextProps.startTimeTimePart,
       endTimeDatePart: nextProps.endTimeDatePart,
       endTimeTimePart: nextProps.endTimeTimePart
     });
    }
  }

  _handleChange = (event) => {
    this.setState({[event.target.dataset.name]: event.target.value})
  };

  _handleDateChange = (dateChange) => {
    this.setState(dateChange)
  };

  render() {
    return (
      <div className="datetime-field">
        <input type="hidden" name="staff_id" value={this.props.staffId || ""} />
        <input
          type="hidden"
          name="custom_schedules[][open]"
          defaultValue={this.props.open}
          />
        <div className="flex items-center">
          <CommonDatepickerField
            date={this.state.startTimeDatePart}
            locale={this.props.locale}
            name="custom_schedules[][start_time_date_part]"
            dataName="startTimeDatePart"
            handleChange={this._handleDateChange}
            calendarfieldPrefix={this.props.calendarfieldPrefix}
            hideCalendar={this.props.hideCalendar}
          />
          <input
            type="time"
            name="custom_schedules[][start_time_time_part]"
            data-name="startTimeTimePart"
            value={this.state.startTimeTimePart || ""}
            size="20"
            onChange={this._handleChange} />
          <span>
            {I18n.t("common.from_when")}
          </span>
        </div>
        <div className="flex items-center">
          <CommonDatepickerField
            date={this.state.endTimeDatePart}
            name="custom_schedules[][end_time_date_part]"
            dataName="endTimeDatePart"
            handleChange={this._handleDateChange}
            calendarfieldPrefix={this.props.calendarfieldPrefix}
            hideCalendar={this.props.hideCalendar}
          />
          <input
            type="time"
            name="custom_schedules[][end_time_time_part]"
            data-name="endTimeTimePart"
            value={this.state.endTimeTimePart || ""}
            size="20"
            onChange={this._handleChange} />
          <span>
            {I18n.t("common.until_when")}
          </span>
        </div>
      </div>
    )
  }
};

export default PersonalScheduleDatetimeFields;
