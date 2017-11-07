import React from "react"
import PropTypes from "prop-types"
import Paper from "./paper/paper.js"
var createReactClass = require('create-react-class');

var HelloWorld = createReactClass({
  propTypes: {
    greeting: PropTypes.string
  },

  render: function() {
    return (
      <div>
      <div>Greeting: {this.props.greeting}</div>
      <Paper />
      </div>
    );
  }
});

export default HelloWorld
