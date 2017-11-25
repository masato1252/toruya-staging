"use strict";

import React from "react";

UI.define("Settings.NewCategories", function() {
  return class NewCategories extends React.Component {
    state = {
      newCategories: [],
      newCategoryValue: ""
    }

    handleCategoryValueChange = (event) => {
      this.setState({newCategoryValue: event.target.value});
    };

    addNewCategory = (event) => {
      event.preventDefault();

      if (!this.state.newCategoryValue.length) {
        return;
      }

      var newCategories = this.state.newCategories.slice(0);
      newCategories.push(this.state.newCategoryValue)

      this.setState({
        newCategories: newCategories,
        newCategoryValue: ""
      })
    };

    removeNewCateogry = (index) => {
      var newCategories = this.state.newCategories;
      newCategories.splice(index, 1)

      this.setState({newCategories: newCategories});

      return;
    };

    render() {
      return (
        <div id="new-categories">
          {this.state.newCategories.map(function(newCategory, i) {
            return(
              <dl className="new-category-row" key={`${newCategory}-${i}`}>
                <dd>
                  <input
                    type="hidden"
                    name="menu[new_categories][]"
                    defaultValue={newCategory}
                    />
                  <input type="checkbox" checked />
                  <label>{newCategory}</label>
                </dd>
                <dd className="remove function">
                  <a className="BTNorange" onClick={this.removeNewCateogry.bind(null, i)}>
                    Cancel
                  </a>
                </dd>
              </dl>
            )
          }.bind(this))}

          <dl className="new-category-area">
            <dd>
              <input
                type="text"
                value={this.state.newCategoryValue}
                placeholder={this.props.categoryLabel}
                onChange={this.handleCategoryValueChange} />
            </dd>
            <dd className="function">
              <a
                className={`BTNtarco ${this.state.newCategoryValue ? null : "disabled"}`} onClick={this.addNewCategory}>
                {this.props.newCategoryBtn}
              </a>
            </dd>
          </dl>
        </div>
      );
    }
  };
});

export default UI.Settings.NewCategories;
