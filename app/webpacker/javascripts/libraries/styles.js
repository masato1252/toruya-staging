"use strict";

const selectCustomStyles = {
  groupHeading: (provided, state) => ({
    ...provided,
    borderBottom: '1px solid #EFEFEF',
    fontSize: '21px',
    color: '#333333'
  }),
}

export {
  selectCustomStyles
};
