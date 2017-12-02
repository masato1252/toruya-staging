"use strict";

import React from "react";
import "./query_sider.js";
import "../../shared/message_bar.js";
import "../../shared/select.js";

UI.define("Reservations.Filter.Dashboard", function() {
  return class ReservationsFilterDashboard extends React.Component {
    constructor(props) {
      super(props);

      this.state = {
        printing_status: "",
        query_processing: false,
        reservations: []
      }
    };

    componentDidMount() {
      let properHeight = window.innerHeight - $("header").innerHeight() - 50;

      $(".contents").height(properHeight);
      $("#searchKeys").height(properHeight);
    };

    updateFilter = (hash) => {
      this.setState(hash);
    };

    updateResult = (reservations) => {
      this.setState({reservations: reservations}, () => {
        this.stopProcessing()
      });
    };

    startProcessing = () => {
      this.setState({query_processing: true});
    };

    stopProcessing = () => {
      this.setState({query_processing: false});
    };

    render() {
      return(
        <div>
          <UI.MessageBar
            status={this.state.printing_status}
            message={this.props.printingMessage}
            closeMessageBar={function() { this.setState({printing_status: ""}) }.bind(this)}
            />
          <div id="dashboard" className="contents">
            <UI.Reservations.Filter.QuerySider
              ref={(c) => {this.querySider = c}}
              {...this.props}
              updateFilter={this.updateFilter}
              startProcessing={this.startProcessing}
            />
          </div>
        </div>
      )
    }
  };
});

export default UI.Reservations.Filter.Dashboard
