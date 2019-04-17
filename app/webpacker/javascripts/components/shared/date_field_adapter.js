import React from "react";
import moment from "moment-timezone";
import DayPickerInput from 'react-day-picker//DayPickerInput';
import MomentLocaleUtils, { parseDate } from 'react-day-picker/moment';
import 'moment/locale/ja';

class DateFieldAdapter extends React.Component {
  constructor(props) {
    super(props);
  };

  openDayPickerCalendar = (event) => {
    event.preventDefault();
    this.dayPickerInput.input.focus();
  };

  render() {
    const selectedDate = this.props.input.value ? moment(this.props.input.value).format("YYYY-MM-DD") : this.props.date
    const fieldName = this.props.input.name;

    return(
      <div className={`datepicker-field`}>
        <DayPickerInput
          ref={(c) => this.dayPickerInput = c }
          {...this.props.input}
          onDayChange={this.props.input.onChange}
          parseDate={parseDate}
          format={[ "YYYY/M/D", "YYYY-M-D" ]}
          dayPickerProps={{
            month: moment(selectedDate).toDate(),
            selectedDays: moment(selectedDate).toDate(),
            localeUtils: MomentLocaleUtils,
            locale: "ja"
          }}
          placeholder="yyyy/mm/dd"
          value={moment(selectedDate, [ "YYYY/M/D", "YYYY-M-D" ]).format("YYYY/M/D")}
          inputProps={{
            disabled: this.props.isDisabled
          }}
        />
        <input
          type="hidden"
          id={fieldName}
          name={fieldName}
          value={selectedDate}
        />
        { !this.props.hiddenWeekDate ? <span>({moment(selectedDate).format("dd")})</span> : null }
        <a href="#" onClick={this.openDayPickerCalendar} className={`BTNtarco calendar-picker ${this.props.isDisabled ? "disabled" : ""}`}>
          <i className="fa fa-calendar fa-2" aria-hidden="true"></i>
        </a>
      </div>
    );
  }
};

export default DateFieldAdapter;
