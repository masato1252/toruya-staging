import React from "react"
import PropTypes from "prop-types"
var createReactClass = require('create-react-class');

var Paper = createReactClass({
  propTypes: {
    greeting: PropTypes.string
  },

  render: function() {
    return (
      <div>
        <div>Paper: {this.props.greeting}</div>
      </div>
    );
  }
});

export default Paper;
