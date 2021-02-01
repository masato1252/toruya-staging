import _ from "lodash";

const initialState = {
  selected_goal: null,
  selected_solution: null,
  selected_company: null,
  end_time: {},
  upsell: {},
  name: null,
  content: null
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

