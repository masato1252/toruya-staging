"use strict";

import React from "react";
import moment from "moment";
import I18n from 'i18n-js/index.js.erb';
import { CustomTimePicker } from 'shared/components';

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
    const newState = { [fieldName]: time };

    // 如果開始時間設置為 00:00，自動設置結束時間為 23:59 (整天)
    if (fieldName === 'startTimeTimePart' && time && time.format('HH:mm') === '00:00') {
      newState.endTimeTimePart = moment('23:59', 'HH:mm');
    }

    this.setState(newState);
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
          <input
            type="date"
            name="custom_schedules[][start_time_date_part]"
            value={this.state.startTimeDatePart || ''}
            onChange={(e) => this._handleDateChange({ startTimeDatePart: e.target.value })}
          />
          <CustomTimePicker
            name="custom_schedules[][start_time_time_part]"
            value={this.state.startTimeTimePart ? this.state.startTimeTimePart.format('HH:mm') : ''}
            onChange={(timeString) => this._handleTimeChange(timeString ? moment(timeString, 'HH:mm') : null, 'startTimeTimePart')}
          />
          <span>
            {I18n.t("common.from_when")}
          </span>
        </div>
        <div className="flex items-center">
          <input
            type="date"
            name="custom_schedules[][end_time_date_part]"
            value={this.state.endTimeDatePart || ''}
            onChange={(e) => this._handleDateChange({ endTimeDatePart: e.target.value })}
          />
          <CustomTimePicker
            name="custom_schedules[][end_time_time_part]"
            value={this.state.endTimeTimePart ? this.state.endTimeTimePart.format('HH:mm') : ''}
            onChange={(timeString) => this._handleTimeChange(timeString ? moment(timeString, 'HH:mm') : null, 'endTimeTimePart')}
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
