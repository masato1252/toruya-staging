"use strict";

import React from "react";
import moment from "moment";
import CommonDatepickerField from "shared/datepicker_field.js";
import { CustomTimePicker } from "shared/components";
import I18n from 'i18n-js/index.js.erb';

class PersonalScheduleDatetimeFields extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      startTimeDatePart: this.props.startTimeDatePart,
      startTimeTimePart: this.props.startTimeTimePart ? moment(this.props.startTimeTimePart, "HH:mm:ss") : null,
      endTimeDatePart: this.props.endTimeDatePart,
      endTimeTimePart: this.props.endTimeTimePart ? moment(this.props.endTimeTimePart, "HH:mm:ss") : null
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
       startTimeTimePart: nextProps.startTimeTimePart ? moment(nextProps.startTimeTimePart, "HH:mm") : null,
       endTimeDatePart: nextProps.endTimeDatePart,
       endTimeTimePart: nextProps.endTimeTimePart ? moment(nextProps.endTimeTimePart, "HH:mm") : null
     });
    }
  }

  _handleChange = (event) => {
    this.setState({[event.target.dataset.name]: event.target.value})
  };

  _handleTimeChange = (time, fieldName) => {
    this.setState({ [fieldName]: time });
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
          <CustomTimePicker
            value={this.state.startTimeTimePart}
            onChange={(time) => this._handleTimeChange(time, 'startTimeTimePart')}
            name="custom_schedules[][start_time_time_part]"
          />
          <span>
            {I18n.t("common.from_when")}
          </span>
        </div>
        <div className="flex items-center">
          <CommonDatepickerField
            date={this.state.endTimeDatePart}
            locale={this.props.locale}
            name="custom_schedules[][end_time_date_part]"
            dataName="endTimeDatePart"
            handleChange={this._handleDateChange}
            calendarfieldPrefix={this.props.calendarfieldPrefix}
            hideCalendar={this.props.hideCalendar}
          />
          <CustomTimePicker
            value={this.state.endTimeTimePart}
            onChange={(time) => this._handleTimeChange(time, 'endTimeTimePart')}
            name="custom_schedules[][end_time_time_part]"
          />
          <span>
            {I18n.t("common.until_when")}
          </span>
        </div>
      </div>
    )
  }
};

export default PersonalScheduleDatetimeFields;
