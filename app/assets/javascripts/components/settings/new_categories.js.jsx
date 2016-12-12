"use strict";

UI.define("Settings.NewCategories", function() {
  var NewCategories = React.createClass({
    getInitialState: function() {
      return ({
        newCategories: [],
        newCategoryValue: ""
      });
    },

    handleCategoryValueChange: function(event) {
      this.setState({newCategoryValue: event.target.value});
    },

    addNewCategory: function(event) {
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
    },

    removeNewCateogry: function(index) {
      var newCategories = this.state.newCategories;
      newCategories.splice(index, 1)

      this.setState({newCategories: newCategories});

      return;
    },

    render: function() {
      return (
        <div id="new-categories">
          <div className="new-category-area">
            <input
              type="text"
              value={this.state.newCategoryValue}
              placeholder={this.props.categoryLabel}
              onChange={this.handleCategoryValueChange} />
            <a
              className={`btn btn-yellow btn-inline ${this.state.newCategoryValue ? null : "disabled"}`} onClick={this.addNewCategory}>
              {this.props.newCategoryBtn}
            </a>
          </div>

          {this.state.newCategories.map(function(newCategory, i) {
            return(
              <dl className="new-category-row" key={`${newCategory}-${i}`}>
                <dd>
                  <input
                    type="hidden"
                    name="menu[new_categories][]"
                    defaultValue={newCategory}
                    />
                  {newCategory}
                </dd>
                <dd className="remove">
                  <a className="btn btn-light-green" onClick={this.removeNewCateogry.bind(null, i)}>
                    Cancel
                  </a>
                </dd>
              </dl>
            )
          }.bind(this))}
        </div>
      );
    }
  });

  return NewCategories;
});
