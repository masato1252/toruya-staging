import _ from "lodash";

const initialState = {
  view: "customers_list",
}

export default (state = initialState, action) => {
  switch(action.type) {
    case "CHANGE_VIEW":
      return {
        ...state,
        view: action.payload.view
      }
    default:
      return state;
  }
}
