//= require "components/shared/customers_list"
//
"use strict";

UI.define("Customers.Dashboard", function() {
  var CustomersDashboard = React.createClass({
    getInitialState: function() {
      return ({
        customers: this.props.customers,
        selected_customer_id: "",
        selectedFilterPatternNumber: ""
      });
    },

    handleCustomerSelect: function(customer_id, event) {
      this.setState({selected_customer_id: customer_id});
    },

    handleAddCustomerToReservation: function(event) {
      event.preventDefault();
      window.location = this.props.addReservationPath + window.location.search + "," + this.state.selected_customer_id;
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
                    <select id="customerSts">
                      <option value="regular" selected="selected">一般</option>
                      <option value="vip">VIP</option>
                    </select>
                  </dt>
                  <dd>
                    <input type="text" id="familyName" placeholder="姓" />
                  </dd>
                  <dd>
                    <input type="text" id="firstName" placeholder="名" />
                  </dd>
                </dl>
                <dl>
                <dt></dt>
                <dd>
                  <input type="text" id="familyNameKana" placeholder="せい" />
                </dd>
                <dd>
                  <input type="text" id="firstNameKana" placeholder="めい" />
                </dd>
              </dl>
                <dl>
                  <dt>
                    <select id="phoneType">
                    <option value="home" selected="selected">自宅</option>
                    <option value="mobile">携帯</option>
                    </select>
                  </dt>
                  <dd>
                  <input type="text" id="phone" placeholder="電話番号" />
                  </dd>
                  <dd>
                  <input type="date" id="dob" placeholder="お誕生日" />
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
              { this.props.addReservationPath ? (
                <dl>
                  <dd id="NAVaddCustomer">
                    <a href="#" className="BTNyellow" onClick={this.handleAddCustomerToReservation}>
                      <span>顧客選択</span>
                    </a>
                  </dd>
                  </dl>) : (
                  <div>
                    <dl>
                      <dd id="NAVnewResv"><a href="#" className="BTNtarco"><span>新規予約</span></a></dd>
                      <dd id="NAVsave"><a href="#" className="BTNyellow"><span>上書き保存</span></a></dd>
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
