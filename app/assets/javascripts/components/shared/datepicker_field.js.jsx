"use strict";

UI.define("Common.DatepickerField", function() {
  var DatepickerField = React.createClass({
    componentDidMount: function() {
      var _this = this;

      $("#" + _this._datepickerId()).datepicker({
        dateFormat: "yy-mm-dd"
      }).datepicker( $.datepicker.regional[ "ja" ] ).
        on("change", _this.props.handleChange)

      $("." + this.props.dataName + " input[type=date]").val("");
      $("." + this.props.dataName + " input[type=date]").val(this.props.date);
    },

    openCalendar: function(event) {
      event.preventDefault();
      $("#" + this._datepickerId()).datepicker('show');
    },

    _datepickerId: function() {
      return `schedule_hidden_date_${this.props.calendarfieldPrefix || "default"}`
    },

    render: function() {
      return(
        <div className={`datepicker-field ${this.props.dataName}`}>
          <input
            type="date"
            data-name={this.props.dataName}
            id={this.props.dataName}
            name={this.props.dataName}
            value={this.props.date}
            onChange={this.props.handleChange}
            className={this.props.className}
            />
            { this.props.date && !this.props.hiddenWeekDate ? <span>({moment(this.props.date).format("dd")})</span> : null }
          <a href="#" onClick={this.openCalendar} className="BTNtarco reservationCalendar">
          <input type="hidden"
            id={this._datepickerId()}
            data-name={this.props.dataName}
            name={this.props.name || this.props.dataName}
            value={this.props.date}
            />
            <i className="fa fa-calendar fa-2" aria-hidden="true"></i>
          </a>
        </div>
      );
    }
  });

  return DatepickerField;
});
