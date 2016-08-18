//= require "components/shared/select"
//= require "components/shared/customers_list"

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
        customers: this.props.reservation.customers || [],
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

    handleCustomerAdd: function(event) {
      event.preventDefault();

      var params = $.param({
        menu_id: this.state.menu_id,
        start_time_date_part: this.state.start_time_date_part,
        start_time_time_part: this.state.start_time_time_part,
        end_time_time_part: this.state.end_time_time_part,
        staff_ids: Array.prototype.slice.call(this.state.staff_ids).join(","),
        customer_ids: this.state.customers.map(function(c) { return c["value"]; }).join(",")
      })

      window.location = `${this.props.customerAddPath}?${params}`
    },

    handleCustomerRemove: function(customer_id, event) {
      var customers = _.reject(this.state.customers, function(option) {
        return option.value == customer_id;
      });

      this.setState({customers: customers})
    },

    _isValidToReserve: function() {
      return this.state.start_time_date_part && this.state.start_time_time_part && this.state.end_time_time_part &&
        this.state.menu_id && this.state.staff_ids.length && this.state.customers.length &&
          $.unique(this.state.staff_ids).length == this.state.menu_min_staffs_number
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

      if (!this.state.start_time_date_part || !this.state.start_time_time_part || !this.state.end_time_time_part) {
        return;
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
        else if (!this.state.staff_ids && this.state.staff_options[i]) {
          value = this.state.staff_options[i]["value"]
        }
        else {
          value = ""
        }

        select_components.push(
          <UI.Select options={this.state.staff_options}
            prefix={`option-${i}`}
            key={`${i}-${value}`}
            defaultValue={value}
            data-name="staff_id"
            includeBlank={value.length == 0}
            onChange={this._handleChange}
        />)
      }

      return select_components
    },

    render: function() {
      return (
        <div>
          <div id="resNew" className="contents">
            <div id="resInfo" className="contBody">
              <h2>予約詳細</h2>
              <div id="resDateTime" className="formRow">
                <dl className="form" id="resDate">
                  <dt>日付</dt>
                  <dd className="input">
                    <input
                      type="date"
                      data-name="start_time_date_part"
                      value={this.state.start_time_date_part}
                      onChange={this._handleChange} />
                  </dd>
                </dl>
                <dl className="form" id="resTime">
                  <dt>時間</dt>
                  <dd className="input">
                    <input
                      type="time"
                      data-name="start_time_time_part"
                      value={this.state.start_time_time_part}
                      onChange={this._handleChange} />
                    〜
                    <input
                      type="time"
                      data-name="end_time_time_part"
                      value={this.state.end_time_time_part}
                      onChange={this._handleChange} />
                      <span className="subinfo">
                        {
                          this.state.start_time_restriction && this.state.end_time_restriction ?
                          `※Business Hour from ${this.state.start_time_restriction} to ${this.state.end_time_restriction}` :
                          "Not working"
                        }
                      </span>
                  </dd>
                </dl>
              </div>
              <div id="resCalMenu" className="formRow">
                <dl className="form" id="resMenu">
                  <dt>メニュー</dt>
                  <dd className="input">
                    <UI.Select options={this.state.menu_options}
                      value={this.state.menu_id}
                      data-name="menu_id"
                      onChange={this._handleChange}
                    />
                  </dd>
                </dl>
                <dl className="form" id="resStaff">
                  <dt>担当者</dt>
                  <dd className="input">
                    {this.renderStaffSelects()}
                  </dd>
                </dl>
                <dl className="form" id="resCal">
                  <dt>予約台帳</dt>
                  <dd className="input"><select id="resCalendar" disabled="">
                    <option value="1">Calendar 1</option>
                    <option value="2">Calendar 2</option>
                    <option value="3">Calendar 3</option>
                  </select><span class="subinfo">※Linked to Menu</span></dd>
                </dl>
              </div>
           </div>

           <div id="customers">
             <h2>顧客
               <a onClick={this.handleCustomerAdd} className="BTNtarco" id="addCustomer">追加</a>
             </h2>

             <UI.Common.CustomersList
               customers={this.state.customers}
               handleCustomerRemove={this.handleCustomerRemove} />
           </div>
          </div>
          <footer>
            <ul id="newResFlow">
              <ol className="done"><i className="fa fa-check" aria-hidden="true"></i>予約詳細</ol>
              <ol><i className="fa fa-chevron-right" aria-hidden="true"></i></ol>
              <ol>顧客</ol>
              <ol><i className="fa fa-chevron-right" aria-hidden="true"></i></ol>
              <ol>完了</ol>
            </ul>
            <ul id="BTNfunctions">
              <li>
                <form acceptCharset="UTF-8" action={this.props.reservationPath} method="post">
                  <input name="utf8" type="hidden" value="✓" />
                  { this.props.reservation.id ?  <input name="_method" type="hidden" value="PUT" /> : null }
                  <input name="authenticity_token" type="hidden" value={this.props.formAuthenticityToken} />
                  <input name="reservation[menu_id]" type="hidden" value={this.state.menu_id} />
                  <input name="reservation[start_time_date_part]" type="hidden" value={this.state.start_time_date_part} />
                  <input name="reservation[start_time_time_part]" type="hidden" value={this.state.start_time_time_part} />
                  <input name="reservation[end_time_time_part]" type="hidden" value={this.state.end_time_time_part} />
                  <input name="reservation[customer_ids]" type="hidden" value={this.state.customers.map(function(c) { return c["value"]; }).join(",")} />
                  <input name="reservation[staff_ids]" type="hidden" value={Array.prototype.slice.call(this.state.staff_ids).join(",")} />
                  <button type="submit" id="BTNsave" className="BTNyellow" disabled={!this._isValidToReserve()}>
                    <i className="fa fa-folder-o" aria-hidden="true"></i>保存
                  </button>
                </form>

              </li>
              <li>
                <button href="" id="BTNdel" className="BTNorange">
                  <i className="fa fa-trash-o" aria-hidden="true"></i>予約を削除
                </button>
              </li>
            </ul>
          </footer>
        </div>
      );
    }
  });
  return ReservationForm;
})
