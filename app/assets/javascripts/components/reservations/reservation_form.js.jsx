//= require "components/shared/select"
//= require "components/shared/customers_list"
//= require "components/shared/processing_bar"
//= require "components/shared/datepicker_field"

"use strict";

UI.define("Reservation.Form", function() {
  var ReservationForm = React.createClass({
    statics: {
      errors: ["shop_closed", "unworking_staff", "time_not_enough", "start_yet", "is_over"],
      warnings: ["interval_too_short", "overlap_reservations", "other_shop", "incapacity_menu", "unschedule_menu",
                 "not_enough_seat", "not_enough_ability"],
      menu_errors: ["time_not_enough", "not_enough_seat", "unschedule_menu", "start_yet", "is_over"],
      menu_danger_errors: ["start_yet", "is_over"],
      staff_errors: ["unworking_staff", "other_shop", "overlap_reservations", "incapacity_menu", "not_enough_ability"],
      staff_danger_errors: ["unworking_staff"]
    },

    getInitialState: function() {
      var menu_id = "";

      return ({
        start_time_date_part: this.props.reservation.startTimeDatePart || "",
        start_time_time_part: this.props.reservation.startTimeTimePart || "",
        end_time_time_part: this.props.reservation.endTimeTimePart || "",
        start_time_restriction: this.props.startTimeRestriction || "",
        end_time_restriction: this.props.endTimeRestriction || "",
        menu_id: this.props.menuId || "",
        customers: this.props.reservation.customers || [],
        staff_ids: this.props.reservation.staffIds || [],
        memo: this.props.reservation.memo || "",
        menu_min_staffs_number: this.props.minStaffsNumber || 0,
        menu_available_seat: this.props.availableSeat,
        menu_group_options: this.props.menuGroupOptions || [],
        staff_options: this.props.staffOptions || [],
        errors: {},
        processing: false,
        submitting: false,
        rough_mode: false
      });
    },

    componentWillMount: function() {
      // this._retrieveAvailableTimes = _.debounce(this._retrieveAvailableTimes, 1000); // delay 1 second
      // this._retrieveAvailableMenus = _.debounce(this._retrieveAvailableMenus, 1000); // delay 1 second
    },

    componentDidMount: function() {
      var _this = this;

      if (this.props.memberMode) {
        this._validateReservation()
      }
      else if (!this.state.menu_id) {
        this._retrieveAvailableTimes()
      }

      this.applySelect2();
    },

    componentDidUpdate: function() {
      if (this._menuErrors().length !== 0) {
        $(".select2-container").addClass(
          this._menuDangerErrors().length === 0 ? "field-warning" : "field-error"
        )
      }
      else {
        $(".select2-container").removeClass("field-error field-warning")
      }
    },

    applySelect2: function() {
      var _this = this;

      $("#select2").select2({
        theme: "bootstrap",
        "language": {
          "noResults": function() {
            return _this.props.noMenuMessage;
          }
        }
      })
      .on("change", _this._handleChange);
    },

    handleCustomerAdd: function(event) {
      event.preventDefault();

      if (this.state.menu_group_options.length == 0 || this._isMeetCustomerLimit()) {
        return;
      }

      var params = $.param({
        from_reservation: true,
        reservation_id: this.props.reservation.id,
        menu_id: this.state.menu_id,
        memo: this.state.memo,
        start_time_date_part: this.state.start_time_date_part,
        start_time_time_part: this.state.start_time_time_part,
        end_time_time_part: this.state.end_time_time_part,
        staff_ids: Array.prototype.slice.call(this.state.staff_ids).join(","),
        customer_ids: this.state.customers.map(function(c) { return c["value"]; }).join(","),
      })

      window.location = `${this.props.customerAddPath}?${params}`
    },

    _customerAddClass: function() {
      if (this.state.menu_group_options.length == 0) {
        return "disabled BTNtarco";
      }
      else if (this._isMeetCustomerLimit()) {
        return "disabled BTNorange"
      }
      else {
        return "BTNtarco"
      }
    },

    _customerWording: function() {
      if (this._isMeetCustomerLimit()) {
        return "満席"
      }
      else {
        return "追加"
      }
    },

    handleCustomerRemove: function(customer_id, event) {
      var _this = this;
      var customers = _.reject(this.state.customers, function(option) {
        return option.value == customer_id;
      });

      this.setState({customers: customers}, function() {
        if (_this.props.memberMode) {
          _this._validateReservation()
        }
        else {
          _this._retrieveAvailableMenus()
        }
      })
    },

    _maxCustomerLimit: function() {
      var _this = this;

      if (this.state.menu_min_staffs_number === 0) {
        return this.state.menu_available_seat
      }
      else if (this.state.menu_min_staffs_number == 1) {
        var selected_staffs = _.filter(_this.state.staff_options, function(staff) {
           return _.contains(_this.state.staff_ids, `${staff.value}`)
        })

        if (selected_staffs[0]) {
          return _.min([selected_staffs[0].handableCustomers, this.state.menu_available_seat]);
        }
      }
      else if (this.state.menu_min_staffs_number > 1) {
        var selected_staffs = _.filter(_this.state.staff_options, function(staff) {
           return _.contains(_this.state.staff_ids, `${staff.value}`)
        })

        var handableCustomers = selected_staffs.map(function(staff) {
          return staff.handableCustomers;
        });

        var minCustomersHandleable = _.min(handableCustomers);

        return _.min([minCustomersHandleable, this.state.menu_available_seat]);
      }
    },

    _isValidReservationTime: function() {
      if (this.state.start_time_restriction && this.state.end_time_restriction &&
          this.state.start_time_time_part && this.state.end_time_time_part) {

        var reservation_start_time = moment(`${this.state.start_time_date_part} ${this.state.start_time_time_part}`);
        var reservation_end_time = moment(`${this.state.start_time_date_part} ${this.state.end_time_time_part}`);

        return reservation_start_time  >= moment(`${this.state.start_time_date_part} ${this.state.start_time_restriction}`) &&
               reservation_end_time <= moment(`${this.state.start_time_date_part} ${this.state.end_time_restriction}`) &&
               reservation_start_time < reservation_end_time

      }
      else {
        return false;
      }
    },

    _isValidCustomerNumber: function() {
      var customersLimit;
      if (customersLimit = this._maxCustomerLimit()) {
        return (customersLimit >= this.state.customers.length);
      }
      else {
        return false;
      }
    },

    _isMeetCustomerLimit: function() {
      var customersLimit;
      if (customersLimit = this._maxCustomerLimit()) {
        return (customersLimit == this.state.customers.length);
      }
      else {
        return false;
      }
    },

    _isAnyWarning: function() {
      return _.intersection(Object.keys(this.state.errors), ReservationForm.warnings).length !== 0 || !this._isValidReservationTime()
    },

    _isValidToReserve: function() {
      if (this.props.memberMode) {
        let errors = _.intersection(Object.keys(this.state.errors), ReservationForm.errors)

        return (
          this.state.start_time_date_part &&
          this.state.start_time_time_part &&
          this.state.end_time_time_part &&
          this.state.menu_id &&
          this.state.staff_ids.length &&
          (this.state.rough_mode ? errors.length == 0 : (errors.length == 0 && !this._isAnyWarning()))
        )
      }
      else {
        return (
          this.state.start_time_date_part &&
          this.state.start_time_time_part &&
          this.state.end_time_time_part &&
          this.state.menu_id &&
          this.state.staff_ids.length &&
          ($.unique(this.state.staff_ids).length >= this.state.menu_min_staffs_number) &&
          this._isValidCustomerNumber()
        )
      }
    },

    _handleChange: function(event) {
      event.preventDefault();
      var eventTargetName = event.target.dataset.name;
      this.setState({[eventTargetName]: event.target.value}, function() {
        if (this.props.memberMode) {
          this._validateReservation();
          // send rough validation request and set the errors
        }
        else {
          // normal custmoer model
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
          }
        }
      }.bind(this))
    },

    _handleStaffChange: function(event) {
      event.preventDefault();
      var selected_staff_ids = $("[data-name='staff_id']").map(function() { return `${$(this).val()}` })

      this.setState({ staff_ids: selected_staff_ids }, function() {
        if (this.props.memberMode) {
          this._validateReservation();
        }
      }.bind(this));
    },

    _retrieveAvailableTimes: function() {
      var _this = this;

      if (!(moment(this.state.start_time_date_part).year() > 1911)) {
        return;
      }

      this.currentRequest = jQuery.ajax({
        url: this.props.availableTimesPath,
        data: {date: this.state.start_time_date_part},
        dataType: "json",
        beforeSend: function() {
          _this.setState({ processing: true });
        }
      })
      .done(
        function(result) {
          _this.setState({
            start_time_restriction: result["start_time_restriction"],
            end_time_restriction: result["end_time_restriction"],
            processing: false
          });
      }).fail(function(errors){
      }).always(function() {
        _this.setState({ processing: false });
      });
    },

    _retrieveAvailableMenus: function() {
      var _this = this;

      if (this.currentRequest != null) {
        this.currentRequest.abort();
      }

      if (!this._isValidReservationTime()) {
        return;
      }

      this.currentRequest = jQuery.ajax({
        url: this.props.availableMenusPath,
        data: {
          reservation_id: this.props.reservation.id,
          start_time_date_part: this.state.start_time_date_part,
          start_time_time_part: this.state.start_time_time_part,
          end_time_time_part: this.state.end_time_time_part,
          customer_ids: this.state.customers.map(function(c) { return c["value"]; }).join(",")
        },
        dataType: "json",
        beforeSend: function() {
          _this.setState({ processing: true });
        }
      })
      .done(
        function(result) {
        _this.setState({menu_group_options: result["menu"]["group_options"],
                        menu_id: result["menu"]["selected_option"]["id"],
                        menu_min_staffs_number: result["menu"]["selected_option"]["min_staffs_number"],
                        menu_available_seat: result["menu"]["selected_option"]["available_seat"],
                        staff_options: result["staff"]["options"],
                        staff_ids: _.map(result["staff"]["options"], function(o) { return o.value }).slice(0, result["menu"]["selected_option"]["min_staffs_number"] || 1)
        });

        if (result["menu"]["group_options"].length == 0) {
          alert(_this.props.noValidMenuAlert);
        }

        setTimeout(function() {
          _this.applySelect2();
        }, 0);
      }).fail(function(errors){
      }).always(function() {
        _this.setState({ processing: false });
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
          menu_id: this.state.menu_id,
          reservation_id: this.props.reservation.id,
          start_time_date_part: this.state.start_time_date_part,
          start_time_time_part: this.state.start_time_time_part,
          end_time_time_part: this.state.end_time_time_part,
          customer_ids: this.state.customers.map(function(c) { return c["value"]; }).join(",")
        },
        dataType: "json",
        beforeSend: function() {
          _this.setState({ processing: true });
        }
      })
      .done(
      function(result) {
        _this.setState({
          menu_min_staffs_number: result["menu"]["selected_option"]["min_staffs_number"],
          staff_options: result["staff"]["options"],
          staff_ids: _.map(result["staff"]["options"], function(o) { return `${o.value}` }).slice(0, result["menu"]["selected_option"]["min_staffs_number"] || 1),
          processing: false
        });
      }).fail(function(errors){
      }).always(function() {
        _this.setState({ processing: false });
      });
    },

    _validateReservation: function() {
      var _this = this;

      if (this.currentRequest != null) {
        this.currentRequest.abort();
      }

      if (!this.state.start_time_date_part) {
        return;
      }

      this.currentRequest = jQuery.ajax({
        url: this.props.validateReservationPath,
        data: {
          menu_id: this.state.menu_id,
          reservation_id: this.props.reservation.id,
          start_time_date_part: this.state.start_time_date_part,
          start_time_time_part: this.state.start_time_time_part,
          end_time_time_part: this.state.end_time_time_part,
          staff_ids: Array.prototype.slice.call(this.state.staff_ids).join(","),
          customer_ids: this.state.customers.map(function(c) { return c["value"]; }).join(",")
        },
        dataType: "json",
        beforeSend: function() {
          _this.setState({ processing: true });
        }
      })
      .done(
      function(result) {
        var staff_ids = _this.state.staff_ids.length ? _this.state.staff_ids : _.map(_this.state.staff_options, function(o) { return o.value }).slice(0, result["min_staffs_number"] || 1)

        _this.setState({
          start_time_restriction: result["start_time_restriction"],
          end_time_restriction: result["end_time_restriction"],
          errors: result["errors"],
          menu_min_staffs_number: result["menu_min_staffs_number"],
          staff_ids: staff_ids
        });
      }).fail(function(errors){
      }).always(function() {
        _this.setState({ processing: false });
      });
    },

    renderStaffSelects: function() {
      var select_components = [];

      if (this.state.menu_min_staffs_number > 0) {
        var option_values = this.state.staff_options.map(function(staff) { return staff.value })

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

          // selected value doesn't in options, e.g. deleted staff.
          if (!_.contains(option_values, value)) {
            value = ""
          }

          select_components.push(
            <div key={`${i}-${value}`}>
              <UI.Select options={this.state.staff_options}
                prefix={`option-${i}`}
                value={value}
                data-name="staff_id"
                includeBlank={value.length == 0}
                onChange={this._handleStaffChange}
                className={
                  this._staffErrors(value) && this._staffErrors(value).length !== 0 ? (
                    this._staffDangerErrors(value).length === 0 ? "field-warning" : "field-error"
                  ) : ""
                }
              />
              <span className="errors">
                {this._staffErrors(value)}
              </span>
            </div>
          )
        }
      }
      else {
        var value = this.state.staff_ids[0];

        select_components.push(
          <div key="no-power">
            <UI.Select options={this.state.staff_options}
              value={value}
              data-name="staff_id"
              includeBlank={true}
              onChange={this._handleStaffChange}
              className={
                this._staffErrors(value) && this._staffErrors(value).length !== 0 ? (
                  this._staffDangerErrors(value).length === 0 ? "field-warning" : "field-error"
                ) : ""
              }
            />
            <span className="errors">
              {this._staffErrors(value)}
            </span>
          </div>
        )
      }

      return select_components
    },

    toggleRoughMode: function() {
      this.setState({rough_mode: !this.state.rough_mode}, function() {
        if (this.state.rough_mode) {
          // Set all menus and staffs
        } else {
          // Clean menus and staffs
        }
      })
    },

    _handleSubmitClick: function(event) {
      // Prevent double clicking.
      event.preventDefault();

      this.setState({submitting: true}, function() {
        if (this._isValidToReserve()) {
          this.submitForm();
        }
      }.bind(this));
    },

    _displayErrors: function(error_reasons) {
      let error_messages = []
      error_reasons.forEach(function(error_reason) {
        if (this.state.errors[error_reason]) {
          if (_.intersection([error_reason], ReservationForm.warnings).length != 0) {
            error_messages.push(<span className="warning" key={error_reason}>{this.state.errors[error_reason]}</span>)
          }
          else {
            error_messages.push(<span className="danger" key={error_reason}>{this.state.errors[error_reason]}</span>)
          }
        }
      }.bind(this))

      return _.compact(error_messages);
    },

    _dateErrors: function() {
      return this._displayErrors(["shop_closed"]);
    },

    _timeErrors: function() {
      return this._displayErrors(["interval_too_short"]);
    },

    _menuErrors: function() {
      return this._displayErrors(ReservationForm.menu_errors);
    },

    _menuDangerErrors: function() {
      return this._displayErrors(ReservationForm.menu_danger_errors);
    },

    _staffErrors: function(staff_id) {
      if (staff_id && this.state.errors[staff_id]) {
        return this._displayErrors(this.state.errors[staff_id]);
      }
      else {
        return ""
      }
    },

    _staffDangerErrors: function(staff_id) {
      if (staff_id && this.state.errors[staff_id]) {
        var dangerStaffErrors = _.intersection(this.state.errors[staff_id], ReservationForm.staff_danger_errors)
        if (dangerStaffErrors.length) {
          return this._displayErrors(dangerStaffErrors)
        }
        else {
          return ""
        }
      }
      else {
        return ""
      }
    },

    _previousReservationOverlap: function() {
      return this._displayErrors(["previous_reservation_interval_overlap"]).length != 0;
    },

    _nextReservationOverlap: function() {
      return this._displayErrors(["next_reservation_interval_overlap"]).length != 0;
    },

    submitForm: function() {
      // Delay submission to make sure that card token, last4, and type are set in real DOM.
      setTimeout(function() {
        jQuery("#save-reservation-form").submit();
      }, 0);
    },

    render: function() {
      return (
        <div>
          <UI.ProcessingBar processing={this.state.processing} processingMessage={this.props.processingMessage} />
          <div id="resNew" className="contents">
            <div id="resInfo" className="contBody">
              <h2>
                <i className="fa fa-calendar-o" aria-hidden="true"></i>
                予約詳細
              </h2>
              <div id="resDateTime" className="formRow">
                <dl className="form" id="resDate">
                  <dt>日付</dt>
                  <dd className="input">
                    <UI.Common.DatepickerField
                      date={this.state.start_time_date_part}
                      dataName="start_time_date_part"
                      name="start_time_date_part"
                      handleChange={this._handleChange}
                      className={this._dateErrors().length == 0 ? "" : "field-error"}
                    />
                    {
                      this.state.start_time_restriction && this.state.end_time_restriction ? (
                        <div className="busHours table">
                          <div className="tableCell">OPEN</div>
                          <div className="tableCell">{this.state.start_time_restriction}〜{this.state.end_time_restriction}</div>
                        </div>
                      ) : (
                        <div className="busHours shopClose table">
                          <div className="tableCell">CLOSE</div>
                        </div>
                      )
                    }
                    <span className="errors">
                      {this._dateErrors()}
                    </span>
                  </dd>
                </dl>
                <dl className="form" id="resTime">
                  <dt>時間</dt>
                  <dd className="input">
                    <input
                      type="time"
                      data-name="start_time_time_part"
                      value={this.state.start_time_time_part}
                      step="300"
                      onChange={this._handleChange}
                      className={this._previousReservationOverlap() ? "field-warning" : ""}
                     />
                    〜
                    <input
                      type="time"
                      data-name="end_time_time_part"
                      value={this.state.end_time_time_part}
                      step="300"
                      onChange={this._handleChange}
                      className={this._nextReservationOverlap() ? "field-warning" : ""}
                      />
                      <span className="errors">
                        {this._isValidReservationTime() ? null : <span className="warning">{this.props.validTimeTipMessage}</span>}
                        {this._timeErrors()}
                      </span>
                  </dd>
                </dl>
              </div>
              <div id="resCalMenu" className="formRow">
                <dl className="form" id="resMenu">
                  <dt>メニュー</dt>
                  <dd className="input">
                    <label htmlFor="select2">
                      <UI.Select options={this.state.menu_group_options}
                        id="select2"
                        value={this.state.menu_id}
                        data-name="menu_id"
                        onChange={this._handleChange}
                      />
                    </label>
                    <span className="errors">
                      {this.state.menu_min_staffs_number === 0 ? <span className="warning">最低スタッフ０</span> : null}
                      {this._menuErrors()}
                    </span>
                  </dd>
                </dl>
                <dl className="form" id="resStaff">
                  <dt>担当者</dt>
                  <dd className="input">
                    {this.renderStaffSelects()}
                  </dd>
                </dl>
              </div>
              <div id="resMemo" className="formRow">
                <dl className="form" id="resMemoRow">
                  <dt>メモ</dt>
                  <dd className="input">
                    <textarea
                      id="memo" placeholder={this.props.memoPlaceholder} data-name="memo" cols="40" rows="4"
                      value={this.state.memo} onChange={this._handleChange} />
                  </dd>
                </dl>
              </div>
           </div>

           <div id="customers">
             <h2>
               <i className="fa fa-user-plus" aria-hidden="true"></i>
               顧客
               <a onClick={this.handleCustomerAdd}
                 className={this._customerAddClass()}
                 id="addCustomer">{this._customerWording()}
               </a>
             </h2>

             <UI.Common.CustomersList
               customers={this.state.customers}
               handleCustomerRemove={this.handleCustomerRemove} />
             <div id="customerLevels">
               <ul>
                 <li className="regular">
                   <span className="customer-level-symbol regular"></span>
                   <span>一般</span>
                 </li>
                 <li className="vip">
                   <span className="customer-level-symbol vip"></span>
                   <span className="wording">VIP</span>
                 </li>
               </ul>
             </div>
           </div>
          </div>
          <footer>
            <ul id="leftFunctions" className="checkbox">
              <li>
                <input
                  type="checkbox"
                  id="confirm-with-errors"
                  checked={this.state.rough_mode}
                  onChange={this.toggleRoughMode}
                />
                <label htmlFor="confirm-with-errors">
                  エラーのままこの予約を保存します
                </label>
              </li>
            </ul>
            <ul id="BTNfunctions">
              {this.props.reservation.id ? (
                <li>
                  <form acceptCharset="UTF-8" action={this.props.reservationPath} method="post">
                    <input name="_method" type="hidden" value="DELETE" />
                    <input name="authenticity_token" type="hidden" value={this.props.formAuthenticityToken} />
                    <button id="BTNdel" className="BTNorange" rel="nofollow" data-confirm={this.props.deleteConfirmationMessage}>
                      <i className="fa fa-trash-o" aria-hidden="true"></i>予約を削除
                    </button>
                  </form>
                </li>) : null
              }
              <li>
                <form acceptCharset="UTF-8" action={this.props.reservationPath} method="post" id="save-reservation-form">
                  <input name="utf8" type="hidden" value="✓" />
                  { this.props.reservation.id ?  <input name="_method" type="hidden" value="PUT" /> : null }
                  <input name="authenticity_token" type="hidden" value={this.props.formAuthenticityToken} />
                  <input name="reservation[menu_id]" type="hidden" value={this.state.menu_id} />
                  <input name="reservation[start_time_date_part]" type="hidden" value={this.state.start_time_date_part} />
                  <input name="reservation[start_time_time_part]" type="hidden" value={this.state.start_time_time_part} />
                  <input name="reservation[end_time_time_part]" type="hidden" value={this.state.end_time_time_part} />
                  <input name="reservation[customer_ids]" type="hidden" value={this.state.customers.map(function(c) { return c["value"]; }).join(",")} />
                  <input name="reservation[staff_ids]" type="hidden" value={Array.prototype.slice.call(this.state.staff_ids).join(",")} />
                  <input name="reservation[memo]" type="hidden" value={this.state.memo} />
                  <input name="reservation[with_warnings]" type="hidden" value={this._isAnyWarning() ? "1" : "0"} />
                  { this.props.fromCustomerId ? <input name="from_customer_id" type="hidden" value={this.props.fromCustomerId} /> : null }
                  { this.props.fromShopId ? <input name="from_shop_id" type="hidden" value={this.props.fromShopId} /> : null }
                  <button type="submit" id="BTNsave" className="BTNyellow"
                    disabled={!this._isValidToReserve() || this.state.submitting}
                    onClick={this._handleSubmitClick}>
                    <i className="fa fa-folder-o" aria-hidden="true"></i>
                    {this.state.submitting ? this.props.processingMessage : "保存"}
                  </button>
                </form>
              </li>
            </ul>
          </footer>
        </div>
      );
    }
  });
  return ReservationForm;
})
