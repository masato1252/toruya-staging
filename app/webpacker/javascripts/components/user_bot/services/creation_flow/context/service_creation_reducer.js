import _ from "lodash";

const initialState = {
  selected_goal: null,
  selected_solution: null,
  end_time: {},
  upsell: {},
}

export default (state = initialState, action) => {
  const payload = action.payload

  switch(action.type) {
    case "SET_ATTRIBUTE":
      return {
        ...state,
        [payload.attribute]: payload.value,
      }
    case "SET_TEMPLATE_VARIABLES":
      return {
        ...state,
        template_variables: {
          ...state.template_variables, [payload.attribute]: payload.value,
        }
      }
    case "SET_NESTED_ATTRIBUTE":
      return {
        ...state,
        [payload.parent_attribute]: {
          ...state[payload.parent_attribute], [payload.attribute]: payload.value,
        }
      }
    case "SET_FLOW":
      return {
        ...state,
        flow: state.flow.map((item, flowIndex) => payload.index == flowIndex ? payload.value : item)
      }
    case "ADD_FLOW":
      return {
        ...state,
        flow: [...state.flow, ""]
      }
    case "REMOVE_FLOW":
      return {
        ...state,
        flow: state.flow.filter((_, index) => payload.index !== index)
      }
    default:
      return state;
  }
}

