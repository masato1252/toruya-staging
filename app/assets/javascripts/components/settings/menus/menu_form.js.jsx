"use strict";

UI.define("Settings.MenuForm", function() {
  var MenuForm = React.createClass({
    getInitialState: function() {
      this.defaultSelectedShopIds = this.props.selectedShops.map(function(shop) { return shop.id });
      this.defaultSelectedCategoryIds = this.props.selectedCategories.map(function(category) { return category.id });
      this.defaultSelectedStaffIds = this.props.selectedStaffs.map(function(staff) { return staff.id });

      var start_date = this.props.selectedReservationSettingRule.start_date ?  moment(this.props.selectedReservationSettingRule.start_date).format("YYYY-MM-DD") : "";
      this.props.selectedReservationSettingRule.start_date = start_date;

      return ({
        menu: this.props.menu,
        selectedStaffs: this.props.selectedStaffs,
        staffMenus: this.props.staffMenus,
        selectedReservationSetting: this.props.selectedReservationSetting || {},
        selectedReservationSettingRule: this.props.selectedReservationSettingRule || {},
        repeatingDateSentence: "",
        selectedShopIds: this.defaultSelectedShopIds
      });
    },

    componentDidMount: function() {
      this._retrieveRepeatingDates()
    },

    selectedStaff: function(staff_id) {
      return _.find(this.state.selectedStaffs, function(selected_staff) {
         return `${selected_staff.id}` == `${staff_id}`
      })
    },

    selectedStaffMenu: function(staff_id) {
      return _.find(this.state.staffMenus, function(staff_menu) { return `${staff_menu.staffId}` == `${staff_id}` })
    },

    switchReservationType: function(event) {
      this.state.selectedReservationSettingRule.reservation_type = event.target.dataset.value;
      this.setState({selectedReservationSettingRule: this.state.selectedReservationSettingRule});
    },

    _handleReservationSettingRuleChange: function(event) {
      if (event.target.dataset.name == "selectedReservationSetting") {
        var selectedReservationSetting = _.find(this.props.reservationSettings, function(reservation_setting) {
          return `${reservation_setting.id}` == event.target.value
        })
        this.setState({selectedReservationSetting: selectedReservationSetting}, this._retrieveRepeatingDates);
      }
      else {
        this.state.selectedReservationSettingRule[event.target.dataset.name] = event.target.value;
        this.setState({selectedReservationSettingRule: this.state.selectedReservationSettingRule}, this._retrieveRepeatingDates);
      }
    },

    _isValidRepeatConditions: function() {
      return (
        this.state.selectedReservationSettingRule.reservation_type == "repeating" &&
        this.state.selectedReservationSettingRule.start_date &&
        this.state.selectedReservationSettingRule.repeats &&
        this.state.selectedReservationSetting
      )
    },

    _retrieveRepeatingDates: function() {
      var _this = this;

      if (this.currentRequest != null) {
        this.currentRequest.abort();
      }

      if (!this._isValidRepeatConditions()) {
        return;
      }

      this.currentRequest = jQuery.ajax({
        url: _this.props.repeatingDatesPath,
        data: {
          reservation_setting_id: _this.state.selectedReservationSetting.id,
          shop_ids: _this.state.selectedShopIds.join(","),
          repeats: _this.state.selectedReservationSettingRule.repeats,
          start_date: _this.state.selectedReservationSettingRule.start_date,
        },
        dataType: "json",
      }).done(
        function(result) {
          _this.setState({repeatingDateSentence: result["sentence"]});
        }).fail(function(errors){
        }).always(function() {
        });
    },

    _handleStaffCheck: function(event) {
      var _this = this;
      var newSelectedStaffs;

      if (this.selectedStaff(event.target.value)) {
        newSelectedStaffs = _.reject(_this.state.selectedStaffs.slice(0), function(selected_staff) {
          return `${selected_staff.id}` == event.target.value
        })
      }
      else {
        newSelectedStaffs = _this.state.selectedStaffs.slice(0)
        newSelectedStaffs.push({id: event.target.value})
      }

      this.setState({selectedStaffs: newSelectedStaffs});
    },

    _handleStaffMaxCustomers: function(event) {
      var newStaffMenus = this.state.staffMenus.slice(0);

      newStaffMenus.forEach(function(staff_menu) {
        if (`${staff_menu.staffId}` == `${event.target.dataset.staffId}`) {
          staff_menu.maxCustomers = event.target.value;
        }
      });

      this.setState({staffMenus: newStaffMenus});
    },

    _handleShopCheck: function() {
      var selectedShopIds = $("#shopSelect input:checked").map(function() { return $(this).val() })
      this.setState({selectedShopIds: Array.prototype.slice.call(selectedShopIds)}, this._retrieveRepeatingDates)
    },

    _handleMenuData: function(event) {
      this.state.menu[event.target.dataset.name] = event.target.value
      this.setState({
        menu: this.state.menu
      })
    },

    _isValidMenu: function() {
      var selectedShopIds = $("#shopSelect input:checked").map(function() { return $(this).val() })
      var maxCustomersList = $("[data-name=max-customers]").map(function() { return $(this).val() });
      var selectedStaffNumber = $("[data-name=staff-selection]:checked").length;

      return this.state.menu.name && this.state.menu.short_name &&
      (this.state.menu.min_staffs_number > 1 ? this.state.menu.max_seat_number : true) &&
      (this.state.menu.min_staffs_number ? _.every(maxCustomersList) && maxCustomersList.length: true) &&
      selectedShopIds.length > 0 &&
      selectedStaffNumber > 0
    },

    render: function() {
      return (
        <form className="new_menu" id="new_menu" action={this.props.saveMenuPath} accept-charset="UTF-8" method="post">
          <input name="utf8" type="hidden" value="✓" />
          {this.props.menu.id ? <input type="hidden" name="_method" value="PUT" /> : null}
          <input type="hidden" name="authenticity_token" value={this.props.formAuthenticityToken} />
          <h3>Menu Informations<strong>必須項目</strong></h3>
          <div id="menuInfo" className="formRow">
            <dl>
              <dt>メニュー名</dt>
              <dd>
                <input
                  placeholder="Menu Name"
                  maxlength="30"
                  size="30"
                  type="text"
                  name="menu[name]"
                  data-name="name"
                  value={this.state.menu.name}
                  onChange={this._handleMenuData}
                  />
              </dd>
            </dl>
            <dl>
              <dt>短縮名</dt>
              <dd>
                <input
                  placeholder="Menu Shorten Name"
                  maxlength="15"
                  size="15"
                  type="text"
                  name="menu[short_name]"
                  data-name="short_name"
                  value={this.state.menu.short_name}
                  onChange={this._handleMenuData}
                  />
              </dd>
            </dl>
            <dl className="menuLength">
              <dt>所要時間</dt>
              <dd>
                <input
                  maxlength="5"
                  size="5"
                  type="number"
                  name="menu[minutes]"
                  data-name="minutes"
                  value={this.state.menu.minutes}
                  onChange={this._handleMenuData}
                />分
              </dd>
            </dl>
            <dl>
              <dt>Interval</dt>
              <dd>
                <input
                  type="number"
                  maxlength="3"
                  size="10"
                  name="menu[interval]"
                  defaultValue={this.state.menu.interval}
                />分
              </dd>
            </dl>
            <dl>
              <dt>最低担当者数</dt>
              <dd>
                <input
                  placeholder="Min Staff"
                  maxlength="10"
                  size="10"
                  className="minStaff"
                  type="number"
                  name="menu[min_staffs_number]"
                  data-name="min_staffs_number"
                  value={this.state.menu.min_staffs_number}
                  onChange={this._handleMenuData}
                />人
              </dd>
            </dl>
            <dl>
              <dt>Max Seat Number</dt>
              <dd>
                <input
                  placeholder="Max Seat Number"
                  maxlength="10"
                  size="10"
                  className="minStaff"
                  type="number"
                  name="menu[max_seat_number]"
                  data-name="max_seat_number"
                  value={this.state.menu.max_seat_number}
                  onChange={this._handleMenuData}
                />人
              </dd>
            </dl>
          </div>

          <h3 className="shopSelect">利用店舗</h3>
          <div id="shopSelect" className="formRow">
              {this.props.shops.map(function(shop) {
                return(
                  <dl className="checkbox" key={`shop-${shop.id}`}>
                    <dd>
                      <input
                        type="checkbox"
                        name="menu[shop_ids][]"
                        id={`shop-${shop.id}`}
                        defaultValue={shop.id}
                        defaultChecked={_.contains(this.defaultSelectedShopIds, shop.id)}
                        onChange={this._handleShopCheck}
                      />
                    <label htmlFor={`shop-${shop.id}`}>{shop.name}</label>
                    </dd>
                  </dl>
                );
              }.bind(this))}
          </div>
          <h3 className="resFrame">予約受付方法</h3>
          <div id="resFrame" className="formRow">
            <dl className="resFrameType">
              <dt>予約枠</dt>
              <dd>
                <UI.Select
                  name="menu[reservation_setting_id]"
                  data-name="selectedReservationSetting"
                  options={this.props.reservationSettings}
                  value ={this.state.selectedReservationSetting.id}
                  onChange={this._handleReservationSettingRuleChange}
                  />
              </dd>
              <dt className="function">
                <a href={this.state.selectedReservationSetting.editPath} className="BTNtarco">Edit 予約枠</a>
              </dt>
              <dt className="function">
                <a href={this.props.addReservationSettingPath} className="BTNyellow">ADD a New 予約枠</a>
              </dt>
            </dl>
            <dl className="menuStarts">
              <dt>受付開始</dt>
              <dd>
                <input
                  type="date"
                  placeholder="開始日"
                  name="menu[menu_reservation_setting_rule_attributes][start_date]"
                  value={this.state.selectedReservationSettingRule.start_date}
                  data-name="start_date"
                  onChange={this._handleReservationSettingRuleChange}
                  />
              </dd>
            </dl>
            <dl className="menuEnds">
              <dt>受付終了</dt>
              <dd>
                <input
                  type="hidden"
                  name="menu[menu_reservation_setting_rule_attributes][reservation_type]"
                  value={this.state.selectedReservationSettingRule.reservation_type}
                  />

                <div className="BTNselect" id="menuEnds">
                  <input
                    type="radio"
                    id="menuEnds1"
                    name="menuEnds"
                    checked={!this.state.selectedReservationSettingRule.reservation_type}
                    onChange={this.switchReservationType}
                    />
                  <label htmlFor="menuEnds1"><span>None</span></label>

                  <input
                    type="radio"
                    id="menuEnds2"
                    name="menuEnds"
                    data-value="repeating"
                    checked={this.state.selectedReservationSettingRule.reservation_type == "repeating"}
                    onChange={this.switchReservationType}
                    />
                  <label htmlFor="menuEnds2"><span>After repeating</span></label>

                  <input
                    type="radio"
                    name="menuEnds"
                    id="menuEnds3"
                    data-value="date"
                    checked={this.state.selectedReservationSettingRule.reservation_type == "date"}
                    onChange={this.switchReservationType}
                    />
                  <label htmlFor="menuEnds3"><span>指定日</span></label>
                </div>
              </dd>
            </dl>
              {
                this.state.selectedReservationSettingRule.reservation_type == "repeating" ? (
                  <dl id="menuEndsRepeat">
                    <dt>Repeat Setting</dt>
                    <dd>
                      <input
                        type="number"
                        size="3"
                        maxlength="3"
                        name="menu[menu_reservation_setting_rule_attributes][repeats]"
                        value={this.state.selectedReservationSettingRule.repeats}
                        data-name="repeats"
                        onChange={this._handleReservationSettingRuleChange}
                        /> times
                        <span className="repeating-sentence">{this.state.repeatingDateSentence}</span>
                    </dd>
                  </dl>
                ) : null
              }
              {
                this.state.selectedReservationSettingRule.reservation_type == "date" ? (
                  <dl id="menuEndsDate">
                    <dt>Ends Date Setting</dt>
                    <dd>
                      <input
                        type="date"
                        placeholder="終了日"
                        name="menu[menu_reservation_setting_rule_attributes][end_date]"
                        defaultValue={
                          this.state.selectedReservationSettingRule.end_date ? moment(this.state.selectedReservationSettingRule.end_date).format("YYYY-MM-DD") : ""
                        }
                        />
                    </dd>
                  </dl>
                ) : null
              }
            </div>
          <h3 className="menuCategory">
            Category
            <a href={this.props.newCategoryPath} className="BTNyellow addNew">ADD a New Category</a>
          </h3>
          <div id="category" className="formRow">
              {this.props.categories.map(function(category) {
                return(
                  <dl className="checkbox" key={`category-${category.id}`}>
                    <dd>
                      <input
                        type="checkbox"
                        name="menu[category_ids][]"
                        id={`category-${category.id}`}
                        defaultValue={category.id}
                        defaultChecked={_.contains(this.defaultSelectedCategoryIds, category.id)}
                      />
                    <label htmlFor={`category-${category.id}`}>{category.name}</label>
                    </dd>
                  </dl>
                );
              }.bind(this))}
          </div>

          <h3>対応従業員</h3>
          <div id="doStaff" className="formRow">
              {this.props.staffs.map(function(staff) {
                return(
                  <dl key={`staff-${staff.id}`}>
                    {
                      this.selectedStaffMenu(staff.id) ? <input type="hidden" name="menu[staff_menus_attributes][][id]" value={this.selectedStaffMenu(staff.id).id} /> : null
                    }
                    {
                      _.contains(this.defaultSelectedStaffIds, staff.id) && !this.selectedStaff(staff.id) ?
                      <input type="hidden" name="menu[staff_menus_attributes][][_destroy]" value="1" /> : null
                    }

                    <dt>{staff.name}</dt>
                    <dd className="capability">
                      <input
                        type="checkbox"
                        className="BTNyesno"
                        name="menu[staff_menus_attributes][][staff_id]"
                        id={`staff-${staff.id}`}
                        value={staff.id}
                        data-name="staff-selection"
                        checked={!!this.selectedStaff(staff.id)}
                        onChange={this._handleStaffCheck}
                      />
                    <label htmlFor={`staff-${staff.id}`}></label>
                    </dd>
                    <dd>
                      {
                        this.selectedStaff(staff.id) ? <input type="number"
                             value={this.selectedStaffMenu(staff.id) ? this.selectedStaffMenu(staff.id).maxCustomers : null}
                             data-name="max-customers"
                             data-staff-id={staff.id}
                             onChange={this._handleStaffMaxCustomers}
                             name="menu[staff_menus_attributes][][max_customers]" /> : null
                      }
                    </dd>
                  </dl>
                );
              }.bind(this))}
          </div>

          <ul id="footerav">
            <li>
              <a className="BTNtarco" href={this.props.cancelPath}>Cancel</a>
            </li>
            <li>
              <input
                type="submit"
                name="commit"
                value="保存"
                className="BTNyellow"
                data-disable-with="保存"
                disabled={!this._isValidMenu()}
                />
            </li>
          </ul>
        </form>
      );
    }
  });
  return MenuForm;
});
