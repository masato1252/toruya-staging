import _ from "lodash";

const initialState = {
  selected_goal: null,
  selected_solution: null,
  selected_company: null,
  end_time: {},
  upsell: {},
  name: null,
  content_url: null,
  message_template: {
    picture: null,
    picture_url: [],
    content: ""
  }
}

export default (state = initialState, action) => {
  const payload = action.payload

  switch(action.type) {
    case "SET_ATTRIBUTE":
      return {
        ...state,
        [payload.attribute]: payload.value,
      }
    case "SET_NESTED_ATTRIBUTE":
      return {
        ...state,
        [payload.parent_attribute]: {
          ...state[payload.parent_attribute], [payload.attribute]: payload.value,
        }
      }
    default:
      return state;
  }
}

