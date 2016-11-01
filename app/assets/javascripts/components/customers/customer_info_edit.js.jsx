"use strict";

UI.define("Customers.CustomerInfoEdit", function() {
  var CustomerInfoEdit = React.createClass({
    getInitialState: function() {
      return ({
      });
    },

    render: function() {
      return (
        <div id="customerInfoEdit" className="contBody">
          <div id="basic">
            <dl>
              <dt>
                <ul>
                  <li>
                    <select>
                      <option value="Contact1">Contact1</option>
                      <option value="Contact2" selected="selected">Contact2</option>
                      <option value="Contact3">Contact3</option>
                    </select>
                  </li>
                  <li>
                    <select id="customerSts" className="vip">
                      <option value="regular">一般</option>
                      <option value="vip" selected="selected">VIP</option>
                    </select>
                  </li>
                </ul>
              </dt>
              <dd>
                <ul>
                  <li><input type="text" id="familyName" placeholder="姓" value="劉" /></li>
                  <li><input type="text" id="firstName" placeholder="名" value="治子" /></li>
                </ul>
                <ul>
                  <li><input type="text" id="familyNameKana" placeholder="せい" value="りゅう" /></li>
                  <li><input type="text" id="firstNameKana" placeholder="めい" value="はるこ" /></li>
                </ul>
              </dd>
              <dd>
                <ul>
                  <li>
                    <i className="fa fa-phone" aria-hidden="true" title="call"></i>
                    <select>
                      <option selected="">Home</option><option>Mobile</option>
                      <option>Work</option>
                    </select>
                  </li>
                </ul>
                <ul>
                  <li>
                    <i className="fa fa-envelope" aria-hidden="true" title="mail"></i>
                    <select>
                      <option>Home</option>
                      <option selected="">Mobile</option>
                      <option>Work</option>
                    </select>
                  </li>
                </ul>
              </dd>
            </dl>
          </div>

        <div id="tabs" className="tabs">
          <a href="customer.html" className="">利用履歴</a>
          <a href="#" className="here">顧客情報</a>
        </div>
        <div id="detailInfo" className="tabBody" style={{height: "425px"}}>
          <ul className="functions">
            <li className="left">
              <a href="customer_info.html">
                <i className="fa fa-chevron-left" aria-hidden="true">
                </i>&nbsp;Back Without Save
              </a>
            </li>
            <li className="right">
              <a href="customer_info.html">Save</a>
            </li>
          </ul>

          <dl className="Address">
            <dt>Address</dt>
            <dd>
              <ul classname="addrzip">
                <li classname="zipcode">〒
                  <input type="number" id="zipcode3" maxlength="3" value="452" />&nbsp;—&nbsp;
                  <input type="number" id="zipcode4" maxlength="4" value="0943" />
                </li>
              </ul>
              <ul className="addrStateCity">
                <li className="state">
                  <select>
                    <option value="北海道">北海道</option>
                    <option value="青森県">青森県</option>
                    <option value="岩手県">岩手県</option>
                    <option value="沖縄県">沖縄県</option>
                  </select>
                </li>
                <li className="city">
                  <input type="text" id="city" value="清須市" />
                </li>
              </ul>
              <ul className="addrRest">
                <li className="address1"><input type="text" id="address1" value="新清洲6-2-5" /></li>
                <li className="address2"><input type="text" id="address2" placeholder="住所２（建物名等）" /></li>
              </ul>
            </dd>
          </dl>
          <dl className="phone">
            <dt>
              Phone<a href="#" className="BTNtarco" title="追加">
              <i className="fa fa-plus" aria-hidden="true"></i></a></dt>
              <dd>
                <ul>
                  <li>
                    <select>
                      <option selected="">Home</option>
                      <option>Mobile</option>
                      <option>Work</option>
                    </select>
                    <input type="tel" id="tel1" value="0524095796" />
                    <a href="#" className="BTNyellow" title="DELETE">
                      <i className="fa fa-minus" aria-hidden="true" title="DELETE"></i>
                    </a>
                  </li>
                  <li>
                    <select>
                      <option>Home</option>
                      <option selected="">Mobile</option>
                      <option>Work</option>
                    </select>
                    <input type="tel" id="tel2" value="08036238534" />
                    <a href="#" className="BTNyellow" title="DELETE">
                      <i className="fa fa-minus" aria-hidden="true" title="DELETE"></i>
                    </a>
                  </li>
                </ul>
              </dd>
            </dl>
            <dl className="email">
              <dt>
                Email<a href="#" className="BTNtarco" title="追加">
                <i className="fa fa-plus" aria-hidden="true"></i></a>
              </dt>
              <dd>
                <ul>
                  <li className="email1">
                    <select>
                      <option selected="">Home</option>
                      <option>Mobile</option>
                      <option>Work</option>

                    </select>
                    <input type="email" id="email1" value="taiwanhimawari@gmail.com" />
                    <a href="#" className="BTNyellow" title="DELETE">
                      <i className="fa fa-minus" aria-hidden="true"></i>
                    </a>
                  </li>

                  <li className="email2">
                    <select>
                      <option>Home</option>
                      <option selected="">Mobile</option>
                      <option>Work</option>
                    </select>
                    <input type="email" id="email2" value="studioha3@softbank.co.jp" />
                    <a href="#" className="BTNyellow" title="DELETE">
                      <i className="fa fa-minus" aria-hidden="true" title="DELETE"></i>
                    </a>
                  </li>

                  <li className="email3">
                    <select>
                      <option>Home</option>
                      <option>Mobile</option>
                      <option selected="">Work</option>
                    </select>
                    <input type="email" id="email3" value="haruko_liu@dreamhint.com" />
                    <a href="#" className="BTNyellow" title="DELETE">
                      <i className="fa fa-minus" aria-hidden="true" title="DELETE"></i>
                    </a>
                  </li>
                </ul>
              </dd>
            </dl>
            <dl className="customerID">
              <dt><label for="customerID">顧客ID</label></dt>
              <dd><input type="text" id="customerID" placeholder="Customer ID" value="DHS0001" /></dd>
            </dl>
            <dl className="dob">
              <dt><label for="dob">DOB</label></dt>
              <dd><select id="dobYear" name="dobYear">
                <option value="1979">1979</option>
                <option value="1980" selected="">1980</option>
                <option value="1981">1981</option>
                <option value="1982">1982</option>
                <option value="2020">2020</option>
              </select>年
              <select id="dobMonth" name="dobMonth">
                <option value="5">5</option>
                <option value="6" selected="">6</option>
                <option value="12">12</option>
              </select>月
              <select id="dobDay" name="dobDay">
                <option value="1">1</option>
                <option value="10">10</option>
                <option value="11" selected="">11</option>
                <option value="12">12</option>
                <option value="31">31</option>
              </select>日
            </dd>
          </dl>
          <dl className="memo">
            <dt><label for="memo">Memo</label></dt>
            <dd><textarea id="memo" placeholder="Memo" cols="30" rows="5"></textarea></dd>
          </dl>
        </div>
      </div>
      );
    }
  });

  return CustomerInfoEdit;
});
