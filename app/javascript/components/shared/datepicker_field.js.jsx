"use strict";

import React from "react";
import moment from "moment-timezone";
import DayPickerInput from 'react-day-picker//DayPickerInput';
import MomentLocaleUtils from 'react-day-picker/moment';
import 'moment/locale/ja';

class CommonDatepickerField extends React.Component {
  constructor(props) {
    super(props);
  };

  openDayPickerCalendar = (event) => {
    event.preventDefault();
    this.dayPickerInput.input.focus();
  };

  handleDateChange = (date) => {
    this.props.handleChange({ [this.props.dataName]: moment(date).format("YYYY-MM-DD") });
  }

  render() {
    return(
      <div className={`datepicker-field ${this.props.dataName}`}>
        <DayPickerInput
          ref={(c) => this.dayPickerInput = c }
          data-name={this.props.dataName}
          name={this.props.dataName}
          onDayChange={this.handleDateChange}
          dayPickerProps={{
            month: this.props.date && moment(this.props.date).toDate(),
            selectedDays: this.props.date && moment(this.props.date).toDate(),
            localeUtils: MomentLocaleUtils,
            locale: "ja"
          }}
          placeholder="dd/mm/yyyy"
          value={this.props.date && moment(this.props.date, [ "DD/MM/YYYY", "YYYY-MM-DD" ]).format("DD/MM/YYYY")}
        />
        <input
          type="hidden"
          id={this.props.dataName}
          name={this.props.name || this.props.dataName}
          value={this.props.date}
        />
        { this.props.date && !this.props.hiddenWeekDate ? <span>({moment(this.props.date).format("dd")})</span> : null }
        <a href="#" onClick={this.openDayPickerCalendar} className="BTNtarco reservationCalendar">
          <i className="fa fa-calendar fa-2" aria-hidden="true"></i>
        </a>
      </div>
    );
  }
};

export default CommonDatepickerField;
