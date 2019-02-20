"use strict";

import React from "react";
import _ from "underscore";
import Select from "../../shared/select.js";
import SettingsNewCategories from "../new_categories.js";

var moment = require('moment-timezone');

class SettingsMenuForm extends React.Component {
  constructor(props) {
    super(props);

    var start_date = this.props.selectedReservationSettingRule.start_date ?  moment(this.props.selectedReservationSettingRule.start_date).format("YYYY-MM-DD") : "";
    this.props.selectedReservationSettingRule.start_date = start_date;

    this.state = {
      menu: this.props.menu,
      selectedReservationSetting: this.props.selectedReservationSetting || {},
      selectedReservationSettingRule: this.props.selectedReservationSettingRule || {},
      menuShopsOptions: this.props.menuShopsOptions,
      menuStaffsOptions: this.props.menuStaffsOptions,
      repeatingDateSentence: ""
    }
  };

  componentDidMount() {
    this._retrieveRepeatingDates()
  };

  selectedMenuStaffOption = (staff_id) => {
    return _.find(this.state.menuStaffsOptions, function(menuStaffOption) {
       return `${menuStaffOption.staffId}` == `${staff_id}`
    })
  };

  selectedMenuShopOption = (shop_id) => {
    return _.find(this.state.menuShopsOptions, function(menuShopOption) {
       return `${menuShopOption.shopId}` == `${shop_id}`
    })
  };

  switchReservationType = (event) => {
    this.state.selectedReservationSettingRule.reservation_type = event.target.dataset.value;
    this.setState({selectedReservationSettingRule: this.state.selectedReservationSettingRule});
  };

  _handleReservationSettingRuleChange = (event) => {
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
  };

  _isValidRepeatConditions = () => {
    return (
      this.state.selectedReservationSettingRule.reservation_type == "repeating" &&
      this.state.selectedReservationSettingRule.start_date &&
      this.state.selectedReservationSettingRule.repeats &&
      this.state.selectedReservationSetting
    )
  };

  _retrieveRepeatingDates = () => {
    var _this = this;

    if (this.currentRequest != null) {
      this.currentRequest.abort();
    }

    if (!this._isValidRepeatConditions()) {
      return;
    }

    var checkedMenuShopsOptions = _.filter(this.state.menuShopsOptions, function(menuShopOption) {
      return menuShopOption.checked
    })

    var checkedShopIds = checkedMenuShopsOptions.map(function(checkedMenuShopOption) {
      return checkedMenuShopOption.shopId
    })

    this.currentRequest = jQuery.ajax({
      url: _this.props.repeatingDatesPath,
      data: {
        reservation_setting_id: _this.state.selectedReservationSetting.id,
        shop_ids: checkedShopIds.join(","),
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
  };

  _handleStaffCheck = (event) => {
    this.selectedMenuStaffOption(event.target.value).checked = !this.selectedMenuStaffOption(event.target.value).checked

    this.setState({menuStaffsOptions: this.state.menuStaffsOptions})
  };

  _handleStaffMaxCustomers = (event) => {
    this.selectedMenuStaffOption(`${event.target.dataset.staffId}`).maxCustomers = event.target.value;

    this.setState({menuStaffsOptions: this.state.menuStaffsOptions})
  };

  _handleShopCheck = (event) => {
    this.selectedMenuShopOption(event.target.value).checked = !this.selectedMenuShopOption(event.target.value).checked

    this.setState({menuShopsOptions: this.state.menuShopsOptions}, this._retrieveRepeatingDates)
  };

  _handleShopMaxSeatNumber = (event) => {
    this.selectedMenuShopOption(`${event.target.dataset.shopId}`).maxSeatNumber = event.target.value;

    this.setState({menuShopsOptions: this.state.menuShopsOptions})
  };

  _handleMenuData = (event) => {
    this.state.menu[event.target.dataset.name] = event.target.value
    this.setState({
      menu: this.state.menu
    })
  };

  _isValidMenu = () => {
    var checkedMenuStaffsOptions = _.filter(this.state.menuStaffsOptions, function(menuStaffOption) {
      return menuStaffOption.checked
    })

    var checkedMenuShopsOptions = _.filter(this.state.menuShopsOptions, function(menuShopOption) {
      return menuShopOption.checked
    })

    var checkedMaxCustomerValues = checkedMenuStaffsOptions.map(function(checkedMenuStaffOption) {
      return checkedMenuStaffOption.maxCustomers
    })

    var checkedMaxSeatNumberValues = checkedMenuShopsOptions.map(function(checkedMenuShopOption) {
      return checkedMenuShopOption.maxSeatNumber
    })

    return (
      this.state.menu.name &&
      this.state.menu.short_name &&
      checkedMenuShopsOptions.length > 0 &&
      checkedMenuStaffsOptions.length > 0 &&
      _.every(checkedMaxSeatNumberValues) &&
      (this.state.menu.min_staffs_number ? _.every(checkedMaxCustomerValues) : true) &&
      (this.state.menu.min_staffs_number === 0 ? true : this.state.menu.min_staffs_number)
    )

  };

  render() {
    return (
      <form className="new_menu" id="new_menu" action={this.props.saveMenuPath} acceptCharset="UTF-8" method="post">
        <input name="utf8" type="hidden" value="✓" />
        {this.props.menu.id ? <input type="hidden" name="_method" value="PUT" /> : null}
        <input type="hidden" name="authenticity_token" value={this.props.formAuthenticityToken} />
        <h3>{this.props.infoLabel}<strong>必須項目</strong></h3>
        <div id="menuInfo" className="formRow">
          <dl>
            <dt>メニュー名</dt>
            <dd>
              <input
                placeholder="メニュー名"
                maxLength="30"
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
                placeholder="短縮名"
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
                maxLength="5"
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
            <dt>{this.props.intervalLabel}</dt>
            <dd>
              <input
                type="number"
                maxLength="3"
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
                maxLength="10"
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
        </div>

        <dl className="header">
          <dt><h3 className="shopSelect">利用店舗</h3></dt>
          <dd><h3 className="max-seat">席数</h3></dd>
        </dl>
        <div id="shopSelect" className="formRow">
            {this.state.menuShopsOptions.map(function(menuShopOption) {
              return(
                <dl className="checkbox" key={`shop-${menuShopOption.shopId}`}>
                  {
                    <input type="hidden" name="menu[shop_menus_attributes][][id]" value={menuShopOption.id || ""} />
                  }

                  {
                    menuShopOption.id && !menuShopOption.checked ?
                    <input type="hidden" name="menu[shop_menus_attributes][][_destroy]" value="1" /> : null
                  }
                  <dd>
                    <input
                      type="checkbox"
                      name="menu[shop_menus_attributes][][shop_id]"
                      id={`shop-${menuShopOption.shopId}`}
                      value={menuShopOption.shopId}
                      checked={menuShopOption.checked}
                      onChange={this._handleShopCheck}
                    />
                    <label htmlFor={`shop-${menuShopOption.shopId}`}>
                      {menuShopOption.name}
                    </label>
                      {
                        menuShopOption.checked ?
                          <input
                            placeholder={this.props.maxCustomersLabel}
                            maxLength="10"
                            size="10"
                            className="minStaff"
                            type="number"
                            name="menu[shop_menus_attributes][][max_seat_number]"
                            data-shop-id={menuShopOption.shopId}
                            value={menuShopOption.maxSeatNumber}
                            onChange={this._handleShopMaxSeatNumber}
                          /> : null
                      }
                      {
                        menuShopOption.checked ? "人" : null
                      }
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
              <Select
                name="menu[reservation_setting_id]"
                data-name="selectedReservationSetting"
                options={this.props.reservationSettings}
                value ={this.state.selectedReservationSetting.id}
                onChange={this._handleReservationSettingRuleChange}
                />
            </dd>
            <dt className="function">
              <a href={this.state.selectedReservationSetting.editPath} className="BTNtarco">{this.props.edit}</a>
            </dt>
            <dt className="function">
              <a href={this.props.addReservationSettingPath} className="BTNyellow">{this.props.addNewReservationSettingBtn}</a>
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
                <div>
                  <input
                    type="radio"
                    id="menuEnds1"
                    name="menuEnds"
                    checked={!this.state.selectedReservationSettingRule.reservation_type}
                    onChange={this.switchReservationType}
                    />
                  <label htmlFor="menuEnds1"><span>{this.props.reservationEndingRuleNone}</span></label>
                </div>

                <div>
                  <input
                    type="radio"
                    id="menuEnds2"
                    name="menuEnds"
                    data-value="repeating"
                    checked={this.state.selectedReservationSettingRule.reservation_type == "repeating"}
                    onChange={this.switchReservationType}
                    />
                  <label htmlFor="menuEnds2"><span>{this.props.reservationEndingRuleRepeating}</span></label>
                </div>

                <div>
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
              </div>
            </dd>
          </dl>
            {
              this.state.selectedReservationSettingRule.reservation_type == "repeating" ? (
                <dl id="menuEndsRepeat">
                  <dt>{this.props.reservationEndingRuleRepeatingSetting}</dt>
                  <dd>
                    <input
                      type="number"
                      size="3"
                      maxLength="3"
                      name="menu[menu_reservation_setting_rule_attributes][repeats]"
                      value={this.state.selectedReservationSettingRule.repeats}
                      data-name="repeats"
                      onChange={this._handleReservationSettingRuleChange}
                      /> {this.props.reservationEndingRuleRepeatingTimes}
                      <span className="repeating-sentence">{this.state.repeatingDateSentence}</span>
                  </dd>
                </dl>
              ) : null
            }
            {
              this.state.selectedReservationSettingRule.reservation_type == "date" ? (
                <dl id="menuEndsDate">
                  <dt>{this.props.reservationEndingRuleEndDateSetting}</dt>
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
          {this.props.categoryLabel}
        </h3>
        <div id="category" className="formRow">
          {this.props.categoriesOptions.map(function(categoryOption) {
            return(
              <dl className="checkbox" key={`category-${categoryOption.id}`}>
                <dd>
                  <input
                    type="checkbox"
                    name="menu[category_ids][]"
                    id={`category-${categoryOption.id}`}
                    defaultValue={categoryOption.id}
                    defaultChecked={categoryOption.checked}
                  />
                <label htmlFor={`category-${categoryOption.id}`}>{categoryOption.name}</label>
                </dd>
              </dl>
            );
          }.bind(this))}
          <SettingsNewCategories
          newCategoryBtn={this.props.newCategoryBtn}
          categoryLabel={this.props.categoryLabel}
            />
        </div>

        <h3>対応従業員</h3>
        <div id="customize-table" className="formRow menu-staffs-table table">
            <ul className="tableTTL">
              <li className="staff-name">対応従業員</li>
              <li className="match">対応</li>
              <li>対応可能人数</li>
            </ul>
            {this.state.menuStaffsOptions.map(function(menuStaffOption) {
              return(
                <dl className="body" key={`staff-${menuStaffOption.staffId}`}>
                  {
                    <input type="hidden" name="menu[staff_menus_attributes][][id]" value={menuStaffOption.id || ""} />
                  }

                  {
                    menuStaffOption.id && !menuStaffOption.checked ?
                    <input type="hidden" name="menu[staff_menus_attributes][][_destroy]" value="1" /> : null
                  }

                  <dt className="staff-name">{menuStaffOption.name}</dt>
                  <dd className="capability">
                    <input
                      type="checkbox"
                      className="BTNyesno"
                      name="menu[staff_menus_attributes][][staff_id]"
                      id={`staff-${menuStaffOption.staffId}`}
                      value={menuStaffOption.staffId}
                      data-name="staff-selection"
                      checked={menuStaffOption.checked}
                      onChange={this._handleStaffCheck}
                    />
                  <label htmlFor={`staff-${menuStaffOption.staffId}`}></label>
                  </dd>
                  <dd>
                    {
                      menuStaffOption.checked ?
                        <input type="number"
                           value={menuStaffOption.maxCustomers}
                           data-name="max-customers"
                           data-staff-id={menuStaffOption.staffId}
                           onChange={this._handleStaffMaxCustomers}
                           name="menu[staff_menus_attributes][][max_customers]" /> : null
                    }
                    {
                      menuStaffOption.checked ? "人" : null
                    }
                  </dd>
                </dl>
              );
            }.bind(this))}
        </div>

        <ul id="footerav">
          <li>
            <a className="BTNtarco" href={this.props.cancelPath}>{this.props.cancelBtn}</a>
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
};

export default SettingsMenuForm;
