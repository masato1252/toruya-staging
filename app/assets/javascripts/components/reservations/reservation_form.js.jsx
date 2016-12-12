//= require "components/shared/select"
//= require "components/shared/customers_list"
//= require "components/shared/processing_bar"

"use strict";

UI.define("Reservation.Form", function() {
  var ReservationForm = React.createClass({
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
        menu_max_seat_number: this.props.maxSeatNumber,
        menu_group_options: this.props.menuGroupOptions || [],
        staff_options: this.props.staffOptions || [],
        processing: false
      });
    },

    componentWillMount: function() {
      // this._retrieveAvailableTimes = _.debounce(this._retrieveAvailableTimes, 1000); // delay 1 second
      // this._retrieveAvailableMenus = _.debounce(this._retrieveAvailableMenus, 1000); // delay 1 second
    },

    componentDidMount: function() {
      if (!this.state.menu_id) {
        this._retrieveAvailableTimes()
      }

      this.applySelect2();
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

      if (this.state.menu_group_options.length == 0) {
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

    handleCustomerRemove: function(customer_id, event) {
      var _this = this;
      var customers = _.reject(this.state.customers, function(option) {
        return option.value == customer_id;
      });

      this.setState({customers: customers}, _this._retrieveAvailableMenus)
    },

    _maxCustomerLimit: function() {
      var _this = this;
      if (this.state.menu_min_staffs_number) {
        var selected_staffs = _.filter(_this.state.staff_options, function(staff) {
           return _.contains(_this.state.staff_ids, `${staff.value}`)
        })
        var staffMaxCustomersTotal = _.reduce(selected_staffs, function(num, staff) {
           return staff.maxCustomers + num;
        }, 0);

        if (this.state.menu_max_seat_number) {
          return _.min([staffMaxCustomersTotal, this.state.menu_max_seat_number]);
        }
        else {
          return staffMaxCustomersTotal;
        }
      }
      else {
        return null;
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
        return true;
      }
    },

    _isValidToReserve: function() {
      return (
        this.state.start_time_date_part &&
        this.state.start_time_time_part &&
        this.state.end_time_time_part &&
        this.state.menu_id &&
        this.state.staff_ids.length &&
        ($.unique(this.state.staff_ids).length >= this.state.menu_min_staffs_number) &&
        this._isValidCustomerNumber()
      )
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
        }
      }.bind(this))
    },

    _handleStaffChange: function(event) {
      event.preventDefault();
      var selected_staff_ids = $("[data-name='staff_id']").map(function() { return `${$(this).val()}` })

      this.setState({ staff_ids: selected_staff_ids });
    },

    _retrieveAvailableTimes: function() {
      var _this = this;

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
                        menu_max_seat_number: result["menu"]["selected_option"]["max_seat_number"],
                        staff_options: result["staff"]["options"],
                        staff_ids: _.map(result["staff"]["options"], function(o) { return o.value }).slice(0, result["menu"]["selected_option"]["min_staffs_number"] || 1)
        });

        if (result["menu"]["group_options"].length == 0) {
          alert(this.props.noValidMenuAlert);
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
          reservation_id: this.props.reservation.id,
          start_time_date_part: this.state.start_time_date_part,
          start_time_time_part: this.state.start_time_time_part,
          end_time_time_part: this.state.end_time_time_part,
          menu_id: this.state.menu_id
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

    _requiredStaffsNumber: function(min_staffs_number) {
      var customerNumber;
      customerNumber = this.state.customers.length;
      customerNumber = customerNumber == 0 ? 1 : customerNumber;
      min_staffs_number = (min_staffs_number == 0 || !min_staffs_number) ? 1 : min_staffs_number
      return min_staffs_number * customerNumber;
    },

    renderStaffSelects: function() {
      var select_components = [];

      if (this.state.menu_min_staffs_number > 0) {
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
              onChange={this._handleStaffChange}
          />)
        }
      }
      else {
        select_components.push(
          <UI.Select options={this.state.staff_options}
            key="no-power"
            defaultValue={this.state.staff_ids[0]}
            data-name="staff_id"
            onChange={this._handleStaffChange}
        />)
      }

      return select_components
    },

    render: function() {
      return (
        <div>
          <UI.ProcessingBar processing={this.state.processing} />
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
                      <span className="danger">
                        { this._isValidReservationTime() ? null : ` ${this.props.validTimeTipMessage}` }
                      </span>
                      <span className="subinfo">
                        {
                          this.state.start_time_restriction && this.state.end_time_restriction ?
                          `${this.props.businessTimeSuggestion} ${this.state.start_time_restriction} ~ ${this.state.end_time_restriction}` :
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
                    <label htmlFor="select2">
                      <UI.Select options={this.state.menu_group_options}
                        id="select2"
                        value={this.state.menu_id}
                        data-name="menu_id"
                        onChange={this._handleChange}
                      />
                    </label>
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
                    <input type="textarea" id="memo" placeholder="Memo" data-name="memo" value={this.state.memo} onChange={this._handleChange}  />
                  </dd>
                </dl>
              </div>
           </div>

           <div id="customers">
             <h2>顧客
               <a onClick={this.handleCustomerAdd} className={`BTNtarco ${this.state.menu_group_options.length != 0 ? "" : "disabled"}`} id="addCustomer">追加</a>
             </h2>

             <UI.Common.CustomersList
               customers={this.state.customers}
               handleCustomerRemove={this.handleCustomerRemove} />
             <div id="customerLevels">
               <ul>
                 <li><i className="customer-level-symbol normal" /><span className="wording">一般</span></li>
                 <li><i className="customer-level-symbol vip" /><span className="wording">VIP</span></li>
               </ul>
             </div>
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
                  <input name="reservation[memo]" type="hidden" value={this.state.memo} />
                  { this.props.fromCustomerId ? <input name="from_customer_id" type="hidden" value={this.props.fromCustomerId} /> : null }
                  { this.props.fromShopId ? <input name="from_shop_id" type="hidden" value={this.props.fromShopId} /> : null }
                  <button type="submit" id="BTNsave" className="BTNyellow" disabled={!this._isValidToReserve()}>
                    <i className="fa fa-folder-o" aria-hidden="true"></i>保存
                  </button>
                </form>

              </li>
              {this.props.reservation.id ? (
                <li>
                  <form acceptCharset="UTF-8" action={this.props.reservationPath} method="post">
                    <input name="_method" type="hidden" value="DELETE" />
                    <input name="authenticity_token" type="hidden" value={this.props.formAuthenticityToken} />
                    <button id="BTNdel" className="BTNorange" rel="nofollow">
                      <i className="fa fa-trash-o" aria-hidden="true"></i>予約を削除
                    </button>
                  </form>
                </li>) : null
              }
            </ul>
          </footer>
        </div>
      );
    }
  });
  return ReservationForm;
})
