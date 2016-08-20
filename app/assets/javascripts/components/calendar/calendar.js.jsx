//= require "components/calendar/day_names"
//= require "components/calendar/week"

"use strict";

UI.define("Calendar", function() {
  var Calendar = React.createClass({
    getInitialState: function() {
      var startDate = this.props.selectedDate ? moment(this.props.selectedDate) : moment().startOf("day");

      return {
        month: startDate.clone()
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
      this.setState({ month: day.date});
      location = `${this.props.reservationsPath}/${day.date.format("YYYY-MM-DD")}`;
    },

    render: function() {
      return <div>
              <div className="header">
                <i className="fa fa-angle-left" onClick={this.previous}></i>
                  <span>{this.state.month.format("MMMM, YYYY")}</span>
                <i className="fa fa-angle-right" onClick={this.next}></i>
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
