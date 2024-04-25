import _ from "lodash";

const initialState = {
  initial: true,
  selected_online_service: null,
  selected_template: null,
  template_variables: {},
  product_content: {
    picture: null,
    picture_url: [],
    desc1: "",
    desc2: ""
  },
  selected_staff: null,
  price: {
    price_types: ["free"],
    price_amounts: {
      "one_time": {
        amount: null
      },
      "multiple_times": {
        times: null,
        amount: null
      }
    }
  },
  normal_price: {
    price_type: "cost", // free/cost
    price_amount: null
  },
  end_time: {
    end_type: "end_at", // never/end_at,
    end_time_date_part: null
  },
  quantity: {
    quantity_type: "limited", // limited, unlimited
    quantity_value: null
  },
  introduction_video: {
    url: null
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
    default:
      return state;
  }
}

