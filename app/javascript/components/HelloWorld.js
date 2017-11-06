import React from "react"
import PropTypes from "prop-types"
var createReactClass = require('create-react-class');

var HelloWorld = createReactClass({
  propTypes: {
    greeting: PropTypes.string
  },

  render: function() {
    return (
      <div>
        <div>Greeting: {this.props.greeting}</div>
      </div>
    );
  }
});
export default HelloWorld
