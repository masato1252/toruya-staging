"use strict";

UI.define("Common.DatepickerField", function() {
  var DatepickerField = React.createClass({
    componentDidMount: function() {
      var _this = this;

      $("#hidden_date").datepicker({
        dateFormat: "yy-mm-dd"
      }).datepicker( $.datepicker.regional[ "ja" ] ).
        on("change", _this.props.handleChange)
    },

    openCalendar: function(event) {
      event.preventDefault();
      $('#hidden_date').datepicker('show');
    },

    render: function() {
      return(
        <div className="datepicker-field">
          <input
            type="date"
            data-name={this.props.dataName}
            id={this.props.dataName}
            name={this.props.dataName}
            value={this.props.date}
            onChange={this.props.handleChange}
            />
          { this.props.date ? `(${moment(this.props.date).format("dd")})` : null }
          <a href="#" onClick={this.openCalendar} className="BTNtarco reservationCalendar">
          <input type="hidden"
            id="hidden_date"
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
