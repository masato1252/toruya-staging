"use strict";

UI.define("Settings.MenuForm", function() {
  var MenuForm = React.createClass({
    getInitialState: function() {
      this.defaultSelectedShopIds = this.props.selectedShops.map(function(shop) { return shop.id });
      this.defaultSelectedStaffIds = this.props.selectedStaffs.map(function(staff) { return staff.id });

      return ({
        menu: this.props.menu,
        selectedStaffs: this.props.selectedStaffs,
        staffMenus: this.props.staffMenus
      });
    },

    selectedStaff: function(staff_id) {
      return _.find(this.state.selectedStaffs, function(selected_staff) {
         return `${selected_staff.id}` == `${staff_id}`
      })
    },

    selectedStaffMenu: function(staff_id) {
      return _.find(this.state.staffMenus, function(staff_menu) { return `${staff_menu.staffId}` == `${staff_id}` })
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

    _handleMenuData: function(event) {
      this.state.menu[event.target.dataset.name] = event.target.value
      this.setState({
        menu: this.state.menu
      })
    },

    _isValidMenu: function() {
      var maxCustomersList = this.state.staffMenus.map((staff_menu) => { return staff_menu.maxCustomers })

      return this.state.menu.name && this.state.menu.shortname && this.state.menu.min_staffs_number &&
      (this.state.menu.min_staffs_number > 1 ? this.state.menu.max_seat_number : true) &&
      (this.state.menu.min_staffs_number == 1 ? _.every(maxCustomersList) : true)
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
                  defaultValue={this.state.menu.name}
                  onChange={this._handleMenuData}
                  />
              </dd>
            </dl>
            <dl>
              <dt>短縮名</dt>
              <dd>
                <input
                  placeholder="Menu Shorten Name"
                  maxlength="10"
                  size="10"
                  type="text"
                  name="menu[shortname]"
                  data-name="shortname"
                  defaultValue={this.state.menu.shortname}
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
                  value="60"
                  name="menu[minutes]"
                  defaultValue={this.state.menu.minutes}
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
                  defaultValue={this.state.menu.min_staffs_number}
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
                  defaultValue={this.state.menu.max_seat_number}
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
                        value={shop.id}
                        defaultChecked={_.contains(this.defaultSelectedShopIds, shop.id)}
                      />
                    <label htmlFor={`shop-${shop.id}`}>{shop.name}</label>
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
                      <input type="hidden" name="menu[staff_menus_attributes][][id]" value={this.selectedStaffMenu(staff.id) ? this.selectedStaffMenu(staff.id).id : ""} />
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
                        checked={!!this.selectedStaff(staff.id)}
                        onChange={this._handleStaffCheck}
                      />
                    <label htmlFor={`staff-${staff.id}`}></label>
                    </dd>
                    <dd>
                      {
                        this.selectedStaff(staff.id) ? <input type="number"
                             defaultValue={this.selectedStaffMenu(staff.id) ? this.selectedStaffMenu(staff.id).maxCustomers : null}
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
