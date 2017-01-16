//= require "components/calendar/day_names"
//= require "components/calendar/week"
//= require "components/shared/select"

"use strict";

UI.define("Calendar", function() {
  var Calendar = React.createClass({
    getInitialState: function() {
      this.startDate = this.props.selectedDate ? moment(this.props.selectedDate) : moment().startOf("day");

      return {
        month: this.startDate.clone(),
        selectedDate: this.startDate.clone()
      };
    },

    previous: function() {
      var month = this.state.month;
      month.add(-1, "M");
      this.setState({ month: month });
    },

    next: function() {
      var month = this.state.month;
      month.add(1, "M");
      this.setState({ month: month });
    },

    select: function(day) {
      this.setState({ month: day.date, selectedDate: day.date });
      location = `${this.props.reservationsPath}/${day.date.format("YYYY-MM-DD")}`;
    },

    handleCalendarSelect: function(event) {
      event.preventDefault();
      this.setState({month: moment(event.target.value)});
    },

    renderYearSelector: function() {
      var years = [];

      var yearStart = this.state.month.clone().add(-3, "Y").startOf('year')

      for (var i = 0; i <= 6; i++) {
        var newYear = yearStart.clone().add(i, "Y");
        var newYearMonth = moment({year: newYear.year(), month: this.state.month.month()});

        years.push({value: newYearMonth.format("YYYY-MM"), label: newYearMonth.format("YYYY")})
      }

      return (
        <UI.Select
          options={years}
          value={this.state.month.format("YYYY-MM")}
          onChange={this.handleCalendarSelect}
        />);
    },

    renderMonthSelector: function () {
      var months = [];
      var yearStart = this.state.month.clone().startOf('year')

      this.props.monthNames.forEach(function(month, i) {
        var newMonth = yearStart.clone().add(i, "M");
        months.push({value: newMonth.format("YYYY-MM"), label: month})
      })

      return (
        <UI.Select
          options={months}
          value={this.state.month.format("YYYY-MM")}
          onChange={this.handleCalendarSelect}
        />);
    },

    render: function() {
      return <div>
              <div className="header">
                <i className="fa fa-angle-left fa-2x" onClick={this.previous}></i>
                  {this.renderYearSelector()}
                  {this.renderMonthSelector()}
                <i className="fa fa-angle-right fa-2x" onClick={this.next}></i>
              </div>
              <UI.DayNames dayNames={this.props.dayNames} />
              {this.renderWeeks()}
             </div>;
    },

    renderWeeks: function() {
      var weeks = [],
          done = false,
          date = this.state.month.clone().startOf("month").add("w" -1).day("Sunday"),
          monthIndex = date.month(),
          count = 0;

          while (!done) {
            weeks.push(<UI.Week key={date.toString()}
                                date={date.clone()}
                                month={this.state.month}
                                select={this.select}
                                selectedDate={this.state.selectedDate}
                                selected={this.state.month} />);
            date.add(1, "w");
            done = count++ > 2 && monthIndex !== date.month();
            monthIndex = date.month();
          }

          return weeks;
    }
  });

  return Calendar;
});
