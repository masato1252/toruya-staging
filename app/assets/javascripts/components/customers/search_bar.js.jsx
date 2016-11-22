"use strict";

UI.define("Customers.SearchBar", function() {
  var SearchBar = React.createClass({
    getInitialState: function() {
      return ({
      });
    },

    render: function() {
      return (
        <ul>
            {
             ["あ", "か", "さ", "た", "な", "は", "ま", "や", "ら", "わ", "A"].map(function(symbol, i) {
               return (
                 <li key={symbol}
                     onClick={this.props.filterCustomers}
                     value={i} >
                   <a href="#"
                      value={i}
                      className={this.props.selectedFilterPatternNumber == `${i}` ? "here" : null }>{symbol}</a>
                 </li>
               )
             }.bind(this))
            }
            <li>
              <i className="fa fa-search fa-2x search-symbol" aria-hidden="true"></i>
              <input type="text" id="search" placeholder="Name" onKeyPress={this.props.SearchCustomers} />
            </li>
         </ul>
      );
    }
  });
  return SearchBar;
});
