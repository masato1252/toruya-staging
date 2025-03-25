"use strict";

import React from "react";
import moment from "moment-timezone";
import DayPickerInput from 'react-day-picker//DayPickerInput';
import MomentLocaleUtils, { parseDate } from 'react-day-picker/moment';
import 'moment/locale/ja';
import { getMomentLocale } from "libraries/helper.js";

class CommonDatepickerField extends React.Component {
  constructor(props) {
    super(props);
    moment.locale(getMomentLocale(props.locale));
  };

  openDayPickerCalendar = (event) => {
    event.preventDefault();
    this.dayPickerInput.input.focus();
  };

  handleDateChange = (date) => {
    if (moment(date, [ "YYYY/M/D", "YYYY-M-D" ]).isValid()) {
      this.props.handleChange({ [this.props.dataName]: moment(date).format("YYYY-MM-DD") });
    }
  }

  render() {
    return(
      <div className={`datepicker-field ${this.props.dataName}`}>
        <DayPickerInput
          ref={(c) => this.dayPickerInput = c }
          data-name={this.props.dataName}
          name={this.props.dataName}
          onDayChange={this.handleDateChange}
          parseDate={parseDate}
          format={[ "YYYY/M/D", "YYYY-M-D" ]}
          dayPickerProps={{
            month: this.props.date && moment(this.props.date).toDate(),
            selectedDays: this.props.date && moment(this.props.date).toDate(),
            localeUtils: MomentLocaleUtils,
            locale: getMomentLocale(this.props.locale)
          }}
          placeholder="yyyy/mm/dd"
          value={this.props.date && moment(this.props.date, [ "YYYY/M/D", "YYYY-M-D" ]).format("YYYY/M/D")}
          inputProps={{
            disabled: this.props.isDisabled
          }}
        />
        <input
          type="hidden"
          id={this.props.dataName}
          name={this.props.name || this.props.dataName}
          value={this.props.date}
        />
        { this.props.date && !this.props.hiddenWeekDate ? <span>({moment(this.props.date).format("dd")})</span> : null }
        { !this.props.hideCalendar &&
          <a href="#" onClick={this.openDayPickerCalendar} className={`btn btn-tarco reservationCalendar ${this.props.isDisabled && "disabled"}`}>
            <i className="fa fa-calendar fa-2" aria-hidden="true"></i>
          </a>}
      </div>
    );
  }
};

export default CommonDatepickerField;
