//= require "components/shared/customers_list"
//
"use strict";

UI.define("Customers.Dashboard", function() {
  var CustomersDashboard = React.createClass({
    getInitialState: function() {
      return ({
        customers: this.props.customers,
        selected_customer_id: "",
        selectedFilterPatternNumber: "",
        customer: this.props.customer
      });
    },

    handleCustomerSelect: function(customer_id, event) {
      this.setState({selected_customer_id: customer_id});
    },

    handleAddCustomerToReservation: function(event) {
      event.preventDefault();
      window.location = this.props.addReservationPath + window.location.search + "," + this.state.selected_customer_id;
    },

    isCustomerdataValid: function() {
      return this.state.customer.first_name || this.state.customer.last_name || this.state.customer.jp_first_name || this.state.customer.jp_last_name
    },

    handleCreateCustomer: function(event) {
      event.preventDefault();

      if (this.isCustomerdataValid()) {
        $("#new_customer_form").submit();
      }
    },

    filterCustomers: function(event) {
      event.preventDefault();
      var _this = this;

      if (this.currentRequest != null) {
        this.currentRequest.abort();
      }

      this.setState({selectedFilterPatternNumber: event.target.value})

      this.currentRequest = jQuery.ajax({
        url: this.props.customersFilterPath,
        data: { pattern_number: event.target.value },
        dataType: "json",
      }).done(
        function(result) {
          _this.setState({customers: result["customers"]});
      }).fail(function(errors){
      }).always(function() {
        _this.setState({Loading: false});
      });
    },

    handleSearch: function(event) {
      if (event.key === 'Enter') {
        console.log('do validate');

        event.preventDefault();
        var _this = this;

        if (this.currentRequest != null) {
          this.currentRequest.abort();
        }

        this.currentRequest = jQuery.ajax({
          url: this.props.customersSearchPath,
          data: { keyword: event.target.value },
          dataType: "json",
        }).done(
          function(result) {
            _this.setState({customers: result["customers"]});
        }).fail(function(errors){
        }).always(function() {
          _this.setState({Loading: false});
        });
      }
    },

    handleCustomerDataChange: function(event) {
      event.preventDefault();
      var newCustomer = this.state.customer;

      newCustomer[event.target.dataset.name] = event.target.value;

      this.setState({customer: newCustomer});
    },

    render: function() {
      return(
        <div>
          <div id="customer" className="contents">
            <div id="resultList" className="sidel">
              <ul>
                <li><i className="customer-level-symbol normal" /><span className="wording">一般</span></li>
                <li><i className="customer-level-symbol vip" /><span className="wording">VIP</span></li>
              </ul>
              <div id="resNew">
                <div id="customers">
                  <UI.Common.CustomersList
                    customers={this.state.customers}
                    handleCustomerSelect={this.handleCustomerSelect}
                    selected_customer_id={this.state.selected_customer_id} />
                </div>
              </div>
            </div>
            <div id="customerInfo" className="contBody">
              <div id="basic">
                <dl>
                  <dt>
                    <UI.Select
                      id="customerSts"
                      options={[{label: "一般", value: "regular"}, {label: "VIP", value: "vip"}]}
                      value={this.state.customer.state}
                      data-name="state"
                      className={this.state.customer.state == "vip" ? "vip" : null}
                      onChange={this.handleCustomerDataChange}
                      />
                  </dt>
                  <dd>
                  <input type="text" id="familyName" placeholder="姓"
                    data-name="last_name"
                    value={this.state.customer.last_name}
                    onChange={this.handleCustomerDataChange}
                  />
                  </dd>
                  <dd>
                  <input type="text" id="firstName" placeholder="名"
                    data-name="first_name"
                    value={this.state.customer.first_name}
                    onChange={this.handleCustomerDataChange}
                  />
                  </dd>
                </dl>
                <dl>
                <dt></dt>
                <dd>
                <input type="text" id="familyNameKana" placeholder="せい"
                  data-name="jp_last_name"
                  value={this.state.customer.jp_last_name}
                  onChange={this.handleCustomerDataChange}
                />
                </dd>
                <dd>
                <input type="text" id="firstNameKana" placeholder="めい"
                  data-name="jp_first_name"
                  value={this.state.customer.jp_first_name}
                  onChange={this.handleCustomerDataChange}
                />
                </dd>
              </dl>
                <dl>
                  <dt>
                    <UI.Select
                      id="phoneType"
                      options={[{label: "自宅", value: "home"}, {label: "携帯", value: "mobile"}]}
                      value={this.state.customer.phone_type}
                      data-name="phone_type"
                      onChange={this.handleCustomerDataChange}
                      />
                  </dt>
                  <dd>
                  <input type="text" id="phone" placeholder="電話番号"
                    data-name="phone_number"
                    value={this.state.customer.phone_number}
                    onChange={this.handleCustomerDataChange}
                  />
                  </dd>
                  <dd>
                  <input type="date" id="dob" placeholder="お誕生日"
                    data-name="birthday"
                    value={this.state.customer.birthday || ""}
                    onChange={this.handleCustomerDataChange}
                  />
                  </dd>
                </dl>
              </div>
              <div id="tabs" className="tabs">
                <a href="#resList" className="here">利用履歴</a>
                <a href="#detailInfo" className="">顧客情報</a>
              </div>
              <div id="resList" className="tabBody">
                <dl className="tableTTL">
                  <dt className="date">ご利用日</dt>
                  <dt className="time">開始<br />終了</dt>
                  <dt className="calendar">カレンダー</dt>
                  <dt className="menu">メニュー</dt>
                </dl>
                <div id="record">
                </div>
               </div>
              <div id="detailInfo" className="tabBody">
                Detailed Info
              </div>
            </div>

            <div id="mainNav">
              { this.props.fromReservation ? (
                <dl>
                  <dd id="NAVaddCustomer">
                    <a href="#" className="BTNyellow" onClick={this.handleAddCustomerToReservation}>
                      <span>顧客選択</span>
                    </a>
                  </dd>
                  </dl>) : (
                  <div>
                    <dl>
                      <dd id="NAVnewResv">
                        <a href={this.props.addReservationPath} className="BTNtarco"><span>新規予約</span></a>
                      </dd>
                      <dd id="NAVsave">
                        <form id="new_customer_form"
                          acceptCharset="UTF-8" action={this.props.addCustomerPath} method="post">
                          <input name="customer[id]" type="hidden" value={this.props.customer.id} />
                          <input name="customer[first_name]" type="hidden" value={this.props.customer.first_name} />
                          <input name="customer[last_name]" type="hidden" value={this.props.customer.last_name} />
                          <input name="customer[jp_last_name]" type="hidden" value={this.props.customer.jp_last_name} />
                          <input name="customer[jp_first_name]" type="hidden" value={this.props.customer.jp_first_name} />
                          <input name="customer[state]" type="hidden" value={this.props.customer.state} />
                          <input name="customer[phone_type]" type="hidden" value={this.props.customer.phone_type} />
                          <input name="customer[phone_number]" type="hidden" value={this.props.customer.phone_number} />
                          <input name="customer[birthday]" type="hidden" value={this.props.customer.birthday} />
                          <input name="authenticity_token" type="hidden" value={this.props.formAuthenticityToken} />
                          <a href="#"
                             className={`BTNyellow ${this.isCustomerdataValid() ? null : "disabled"}`} onClick={this.handleCreateCustomer}><span>上書き保存</span>
                          </a>
                        </form>
                      </dd>
                    </dl>
                    <dl id="calStatus">
                      <dd><span className="reservation-state reserved"></span>予約</dd>
                      <dd><span className="reservation-state checkin"></span>チェックイン</dd>
                      <dd><span className="reservation-state checkout"></span>チェックアウト</dd>
                      <dd><span className="reservation-state noshow"></span>未来店</dd>
                      <dd><span className="reservation-state pending"></span>承認待ち</dd>
                    </dl>
                  </div>
                  )
              }
            </div>
          </div>
          <footer>
          <ul>
              {
               ["あ", "か", "さ", "た", "な", "は", "ま", "や", "ら", "わ", "A"].map(function(symbol, i) {
                 return (
                   <li key={symbol}
                       onClick={this.filterCustomers}
                       value={i} >
                     <a href="#"
                        value={i}
                        className={this.state.selectedFilterPatternNumber == `${i}` ? "here" : null }>{symbol}</a>
                   </li>
                 )
               }.bind(this))
              }
              <li>
                <i className="fa fa-search fa-2x search-symbol" aria-hidden="true"></i>
                <input type="text" id="search" placeholder="Name or TEL" onKeyPress={this.handleSearch} />
              </li>
             </ul>
          </footer>
        </div>
      );
    }
  });

  return CustomersDashboard;
});
