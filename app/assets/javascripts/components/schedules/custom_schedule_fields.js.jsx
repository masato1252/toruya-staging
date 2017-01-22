"use strict";

UI.define("CustomScheduleFields", function() {
  var CustomScheduleFields  = React.createClass({
    getInitialState: function() {
      return ({
        start_time_date_part: this.props.schedule.startTimeDatePart || "",
        start_time_time_part: this.props.schedule.startTimeTimePart || "",
        end_time_time_part: this.props.schedule.endTimeTimePart || "",
        reason: this.props.schedule.reason || "",
        delete_flag: false
      });
    },

    _handleChnage: function(event) {
      this.setState({[event.target.dataset.name]: event.target.value})
    },

    _handleCustomRow: function(event) {
      event.preventDefault();
      this.setState({delete_flag: !this.state.delete_flag})
    },

    render: function() {
      if (this.state.delete_flag) {
        return (
          <div>
            {
              this.props.schedule.id ?
              <input type="hidden" name="custom_schedules[][id]" value={this.props.schedule.id} />
              : null
            }
            {
              this.props.schedule.id ?
              <input type="hidden" name="custom_schedules[][_destroy]" defaultValue="true" />
                : null
            }
          </div>
        )
      }

      return (
        <dl>
          {
            this.props.schedule.id ?
            <input type="hidden" name="custom_schedules[][id]" value={this.props.schedule.id} />
            : null
          }
          <input
            type="hidden"
            name="custom_schedules[][open]"
            defaultValue={this.props.open}
            />
          <dt>
            <input
              type="date"
              name="custom_schedules[][start_time_date_part]"
              data-name="start_time_date_part"
              value={this.state.start_time_date_part}
              onChange={this._handleChnage} />
          </dt>
          <dd className="startTime">
            <input
              type="time"
              name="custom_schedules[][start_time_time_part]"
              data-name="start_time_time_part"
              value={this.state.start_time_time_part}
              size="20"
              onChange={this._handleChnage} />
          </dd>
          <dd className="endTime">
            <input
              type="time"
              name="custom_schedules[][end_time_time_part]"
              data-name="end_time_time_part"
              value={this.state.end_time_time_part}
              size="20"
              onChange={this._handleChnage} />
          </dd>
          {this.props.open ? null :
            (
            <dd className="closeReason">
              <input
                type="text"
                name="custom_schedules[][reason]"
                data-name="reason"
                value={this.state.reason}
                placeholder={this.props.closingReason}
                size="40"
                onChange={this._handleChnage} />
            </dd>
          )}
          <dd className="add">
            <a href="#" className="btn btn-reset btn-danger" onClick={this._handleCustomRow}>
              {this.props.deleteBtn}
            </a>
          </dd>
        </dl>
      );
    }
  });

  return CustomScheduleFields;
});
