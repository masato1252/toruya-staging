import _ from "lodash";

const initialState = {
  id: null,
  query_type: null,
  query: null,
  content: "",
  schedule_at: null,
  customers_count: null
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

