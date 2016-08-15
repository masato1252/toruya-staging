//= require "components/shared/select"
//
"use strict";

UI.define("Reservation.Form", function() {
  var ReservationForm = React.createClass({
    getInitialState: function() {
      return ({
        start_time_date_part: this.props.reservation.startTimeDatePart || "",
        start_time_time_part: this.props.reservation.startTimeTimePart || "",
        end_time_time_part: this.props.reservation.endTimeTimePart || "",
        start_time_restriction: this.props.startTimeRestriction || "",
        end_time_restriction: this.props.endTimeRestriction || "",
        menu_id: this.props.reservation.menuId || "",
        customer_ids: this.props.reservation.customerIds || [],
        staff_ids: this.props.reservation.staffIds || [],
        menu_min_staffs_number: this.props.minStaffsNumber || 0,
        menu_options: this.props.menuOptions || [],
        staff_options: this.props.staffOptions || []
      });
    },

    componentWillMount: function() {
      this._retrieveAvailableTimes = _.debounce(this._retrieveAvailableTimes, 1000); // delay 1 second
      this._retrieveAvailableMenus = _.debounce(this._retrieveAvailableMenus, 200); // delay 1 second
    },

    componentDidMount: function() {
      if (!this.state.menu_id) {
        this._retrieveAvailableTimes()
      }
    },

    handleCustomerSelect: function() {
      this.setState({customer_ids: $("[data-name='customer_id']").map(function() { return $(this).val() })});
    },

    _isValidToReserve: function() {
      //TODO need customer_ids
      return this.state.start_time_date_part && this.state.start_time_time_part && this.state.end_time_time_part &&
        this.state.menu_id && this.state.staff_ids.length
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
          case "end_time_time_part":
            this._retrieveAvailableMenus();
            break;
          case "menu_id":
            this._retrieveAvailableStaffs();
            break;
          case "staff_id":
            this.setState({ staff_ids: $("[data-name='staff_id']").map(function() { return $(this).val() }) });
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
        data: {
          start_time_date_part: this.state.start_time_date_part,
          start_time_time_part: this.state.start_time_time_part,
          end_time_time_part: this.state.end_time_time_part
        },
        dataType: "json",
      }).done(
      function(result) {
        _this.setState({menu_options: result["menu"]["options"],
                        menu_id: result["menu"]["selected_option"]["id"],
                        menu_min_staffs_number: result["menu"]["selected_option"]["min_staffs_number"],
                        staff_options: result["staff"]["options"]
        }, function() {
          this.setState({staff_ids: _.map(this.state.staff_options, function(o) { return o.value }) });
        });

        if (result["menu"]["options"].length == 0) {
          alert("No available menu");
        }
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
          start_time_date_part: this.state.start_time_date_part,
          start_time_time_part: this.state.start_time_time_part,
          end_time_time_part: this.state.end_time_time_part,
          menu_id: this.state.menu_id
        },
        dataType: "json",
      }).done(
      function(result) {
        _this.setState({
          menu_min_staffs_number: result["menu"]["selected_option"]["min_staffs_number"],
          staff_options: result["staff"]["options"]
        }, function() {
          this.setState({staff_ids: _.map(this.state.staff_options, function(o) { return o.value }) });
        });
      }).fail(function(errors){
      }).always(function() {
        _this.setState({Loading: false});
      });
    },

    renderStaffSelects: function() {
      var select_components = [];
      for (var i = 0; i < this.state.menu_min_staffs_number; i++) {
        var value;
        if (this.state.staff_ids[i]) {
          value = this.state.staff_ids[i]
        }
        else if (this.state.staff_options[i]) {
          value = this.state.staff_options[i]["value"]
        }
        else {
          value = ""
        }

        select_components.push(
          <UI.Select options={this.state.staff_options}
            prefix={`option-${i}`}
            key={value}
            value={value}
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
              data-name="start_time_date_part"
              value={this.state.start_time_date_part}
              onChange={this._handleChange} />
          </div>
          <div>
            <input
              type="time"
              data-name="start_time_time_part"
              value={this.state.start_time_time_part}
              onChange={this._handleChange} />
            ~
            <input
              type="time"
              data-name="end_time_time_part"
              value={this.state.end_time_time_part}
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
              data-name="menu_id"
              onChange={this._handleChange}
            />
          </div>
          <div class="field">
            {this.renderStaffSelects()}
            </div>
            <form acceptCharset="UTF-8" action={this.props.reservationCreatePath} method="post">
              <input name="utf8" type="hidden" value="✓" />
              <input name="authenticity_token" type="hidden" value={this.props.formAuthenticityToken} />
              <input name="reservation[menu_id]" type="hidden" value={this.state.menu_id} />
              <input name="reservation[start_time_date_part]" type="hidden" value={this.state.start_time_date_part} />
              <input name="reservation[start_time_time_part]" type="hidden" value={this.state.start_time_time_part} />
              <input name="reservation[end_time_time_part]" type="hidden" value={this.state.end_time_time_part} />
              <input name="reservation[customer_ids]" type="hidden" value={this.state.customer_ids} />
              <input name="reservation[staff_ids]" type="hidden" value={this.state.staff_ids} />
              <button type="submit" disabled={!this._isValidToReserve()}>Reserve</button>
            </form>
        </div>
      );
    }
  });
  return ReservationForm;
})
