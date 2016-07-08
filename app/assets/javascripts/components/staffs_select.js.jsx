//= require "components/shared/select"
//= require "components/shared/custom_hidden_field"

"use strict";

UI.define("StaffsSelect", function() {
  var StaffsSelect = React.createClass({
    getInitialState: function() {
      return {
        optionStaffs: this.props.optionStaffs,
        validStaffs: this.props.validStaffs
      }
    },

    _handleOptionStaffClick: function(event) {
      var validStaffs = this.state.validStaffs.slice(0);
      var originalOptionStaffs = this.state.optionStaffs.slice(0);

      var newOptionStaffs = _.reject(originalOptionStaffs, function(staff){ return staff.value == event.target.value; });
      var newValidStaff = _.find(originalOptionStaffs, function(staff){ return staff.value == event.target.value; });
      validStaffs.push(newValidStaff);

      this.setState({validStaffs: validStaffs, optionStaffs: _.sortBy(newOptionStaffs, "value")});
    },

    _handleVaildStaffClick: function(event) {
      var originalValidStaff = this.state.validStaffs.slice(0);
      var optionStaffs = this.state.optionStaffs.slice(0);

      var newValidStaffs = _.reject(originalValidStaff, function(staff){ return staff.value == event.target.value; });
      var newOptionStaff = _.find(originalValidStaff, function(staff){ return staff.value == event.target.value; });
      optionStaffs.push(newOptionStaff);

      this.setState({validStaffs: newValidStaffs, optionStaffs: _.sortBy(optionStaffs, "value")});
    },

    render: function() {
      return (
        <div>
          <UI.Select options={this.state.optionStaffs}
            value=""
            onChange={this._handleOptionStaffClick}
            includeBlank={true}
          />
          {this._renderValidStaff()}
        </div>
      )
    },

    _renderValidStaff: function() {
      if (this.state.validStaffs.length) {
        return(
          this.state.validStaffs.map(function(staff) {
            return(
              <UI.CustomHiddenField
              key={staff.value}
              label={staff.label}
              value={staff.value}
              onClick={this._handleVaildStaffClick}
              name="menu[staff_ids][]" />
            );
          }.bind(this))
        )
      }
      else {
        return <input type="hidden" value="" name="menu[staff_ids][]" />
      }
    }
  });

  return StaffsSelect
});
