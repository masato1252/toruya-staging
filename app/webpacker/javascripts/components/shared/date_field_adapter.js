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
    const { error, touched } = this.props.meta;
    const timezone = this.props.timezone || "Asia/Tokyo";

    // onDayChange decide the YYYY-MM-DD is the real value format
    // value property decide the YYYY/M/D is the display format
    return(
      <div className={`datepicker-field`}>
        <div className={`fake-date-field ${error && touched ? "field-error" : ""} ${this.props.className}`}>
          <DayPickerInput
            ref={(c) => this.dayPickerInput = c }
            {...this.props.input}
            onDayChange={(date) => {
              const parsedDate = moment.tz(date, this.props.timezone).format("YYYY-MM-DD")
              this.props.input.onChange(parsedDate);

              if (this.props.dateChangedCallback) {
                this.props.dateChangedCallback(parsedDate);
              }
            }}
            parseDate={parseDate}
            format={[ "YYYY/M/D", "YYYY-M-D", "YYYY-MM-DD" ]}
            dayPickerProps={{
              month: moment(selectedDate).toDate(),
              selectedDays: moment(selectedDate).toDate(),
              localeUtils: MomentLocaleUtils,
              locale: "ja"
            }}
            placeholder="yyyy/mm/dd"
            value={moment(selectedDate, [ "YYYY/M/D", "YYYY-M-D", "YYYY-MM-DD" ]).format("YYYY/M/D")}
            inputProps={{
              disabled: this.props.isDisabled
            }}
          />
        </div>
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
