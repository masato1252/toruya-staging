//= require "components/shared/select"
//
"use strict";

UI.define("Reservation.Form", function() {
  var ReservationForm = React.createClass({
    getInitialState: function() {
      return ({
        start_time_date_part: this.props.reservation.startTimeDatePart || "",
        start_time_time_part: this.props.reservation.startTimeTimePart || "",
        end_time: this.props.reservation.endTime || "",
        start_time_restriction: "",
        end_time_restriction: "",
        menu_id: {},
        min_staffs_number: 0,
        menu_options: [],
        staff_options: []
      });
    },

    componentWillMount: function() {
      this._retrieveAvailableTimes = _.debounce(this._retrieveAvailableTimes, 1000); // delay 1 second
      this._retrieveAvailableMenus = _.debounce(this._retrieveAvailableMenus, 200); // delay 1 second
    },

    componentDidMount: function() {
      this._retrieveAvailableTimes()
    },

    _handleChange: function(event) {
      event.preventDefault();
      var eventTargetName = event.target.dataset.name;
      this.setState({[eventTargetName]: event.target.value}, function(){
        switch(eventTargetName) {
          case "start_time_date_part":
            this._retrieveAvailableTimes();
            break;
          case "start_time_time_part":
          case "end_time":
            this._retrieveAvailableMenus();
            break;
          case "menu_id":
            this._retrieveAvailableStaffs();
            break;
        }
      }.bind(this))
    },

    _retrieveAvailableTimes: function() {
      var _this = this;

      this.currentRequest = jQuery.ajax({
        url: this.props.availableTimesPath,
        data: {date: this.state.start_time_date_part},
        dataType: "json",
      }).done(
        function(result) {
          _this.setState({start_time_restriction: result["start_time_restriction"], end_time_restriction: result["end_time_restriction"]});
      }).fail(function(errors){
      }).always(function() {
        _this.setState({Loading: false});
      });
    },

    _retrieveAvailableMenus: function() {
      var _this = this;

      if (this.currentRequest != null) {
        this.currentRequest.abort();
      }

      this.currentRequest = jQuery.ajax({
        url: this.props.availableMenusPath,
        data: {date: this.state.start_time_date_part, start_time_time_part: this.state.start_time_time_part, end_time: this.state.end_time},
        dataType: "json",
      }).done(
      function(result) {
          _this.setState({menu_options: result["menu"]["options"],
                          menu_id: result["menu"]["selected_option"]["id"],
                          menu_min_staffs_number: result["menu"]["selected_option"]["min_staffs_number"],
                          staff_options: result["staff"]["options"]
          });
      }).fail(function(errors){
      }).always(function() {
        _this.setState({Loading: false});
      });
    },

    _retrieveAvailableStaffs: function() {
      var _this = this;

      if (this.currentRequest != null) {
        this.currentRequest.abort();
      }

      this.currentRequest = jQuery.ajax({
        url: this.props.availableStaffsPath,
        data: {
          date: this.state.start_time_date_part,
          start_time_time_part: this.state.start_time_time_part,
          end_time: this.state.end_time,
          menu_id: this.state.menu_id
        },
        dataType: "json",
      }).done(
      function(result) {
        _this.setState({
          menu_min_staffs_number: result["menu"]["selected_option"]["min_staffs_number"],
          staff_options: result["staff"]["options"]
        });
      }).fail(function(errors){
      }).always(function() {
        _this.setState({Loading: false});
      });
    },

    renderStaffSelects: function() {
      var select_components = [];
      for (var i = 0; i < this.state.menu_min_staffs_number; i++) {
        select_components.push(<UI.Select options={this.state.staff_options}
          key={i}
          value={this.state.staff_options[i] ? this.state.staff_options[i]["value"] : ""}
          includeBlank={!this.state.staff_options[i]}
          blankOption="No valid option"
          name="reservation[staff_id]"
          data-name="staff_id"
          onChange={this._handleChange}
        />)
      }
      return select_components
    },

    render: function() {
      return (
        <div>
          <div>
            <input
              type="date"
              name="reservation[start_time_date_part]"
              data-name="start_time_date_part"
              value={this.state.start_time_date_part}
              onChange={this._handleChange} />
          </div>
          <div>
            <input
              type="time"
              name="reservation[start_time_time_part]"
              data-name="start_time_time_part"
              value={this.state.start_time_time_part}
              onChange={this._handleChange} />
            ~
            <input
              type="time"
              name="reservation[end_time]"
              data-name="end_time"
              value={this.state.end_time}
              onChange={this._handleChange} />
              {
                this.state.start_time_restriction && this.state.end_time_restriction ?
                  <span>※Business Hour from {this.state.start_time_restriction} to {this.state.end_time_restriction}</span> :
                  <span>Not working</span>
              }
          </div>
          <div class="field">
            <UI.Select options={this.state.menu_options}
              value={this.state.menu_id}
              name="reservation[menu_id]"
              data-name="menu_id"
              onChange={this._handleChange}
            />
          </div>
          <div class="field">
            {this.renderStaffSelects()}
          </div>
        </div>
      );
    }
  });
  return ReservationForm;
})
