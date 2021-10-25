import _ from "lodash";

const initialState = {
  selected_solution: null,
  name: null,
  content_url: null,
  note: null
}

export default (state = initialState, action) => {
  const payload = action.payload

  switch(action.type) {
    case "SET_ATTRIBUTE":
      return {
        ...state,
        [payload.attribute]: payload.value,
      }
    default:
      return state;
  }
}

