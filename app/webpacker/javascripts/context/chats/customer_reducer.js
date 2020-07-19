// mapping with
// app/serializers/social_customer_serializer.rb
//
// @customers:
// {
//   <channel_id> => [
//      {
//        id : <customer social user id>,
//        shop_customer: <toruya shop customer object>,
//        channel_id: <channel_id>,
//        name: <message name>,
//        unread_message_count: 0,
//        has_more_messages: true|false|null, // null: never load, true: has more messages, false: has no messages
//        conversation_state: bot|one_on_one
//      },
//   ]
// }

const initialState = {
  selected_customer: {},
  customers: {},
  matched_shop_customers: [],
  customers_loaded: false
}

export default (state = initialState, action) => {
  let channel_customers, social_customer, shop_customer;

  switch(action.type) {
    case "APPEND_CUSTOMERS":
      const new_customers = [...(state.customers[action.payload.channel_id] || []), ...action.payload.customers ]

      return {
        ...state,
        customers: {
          ...state.customers,
          [action.payload.channel_id]: _.uniqWith(new_customers, (a, b) => a.id === b.id)
        },
        customers_loaded: true
      }
    case "CUSTOMER_NEW_MESSAGE":
      if (state.selected_customer.id !== action.payload.customer.id) {
        channel_customers = state.customers[action.payload.customer.channel_id] || []

        return {
          ...state,
          customers: {
            ...state.customers,
            [action.payload.customer.channel_id]: channel_customers.map(el => (el.id === action.payload.customer.id ? {...el, unread_message_count: el.unread_message_count + 1} : el))
          }
        }
      }
      else {
        return state
      }
    case "SELECT_CUSTOMER":
      if (action.payload) {
        channel_customers = state.customers[action.payload.channel_id] || []
        const matched_customer = channel_customers.find(customer => customer.id === action.payload.id) || action.payload || {}

        return {
          ...state,
          selected_customer: {...matched_customer, unread_message_count: 0},
          customers: {
            ...state.customers,
            [action.payload.channel_id]: channel_customers.map(el => (el.id === action.payload.id ? {...el, unread_message_count: 0} : el))
          }
        }
      }
      else {
        return state
      }
    case "TOGGLE_CUSTOMER_CONVERSATION_STATE":
      channel_customers = state.customers[action.payload.channel_id] || []

      return {
        ...state,
        selected_customer: action.payload.id !== state.selected_customer.id ? state.selected_customer : { ...state.selected_customer, conversation_state: state.selected_customer.conversation_state === "one_on_one" ? "bot" : "one_on_one" },
        customers: {
          ...state.customers,
          [action.payload.channel_id]: channel_customers.map(el => (el.id === action.payload.id ? {...el, conversation_state: el.conversation_state === "one_on_one" ? "bot" : "one_on_one"} : el))
        }
      }
    case "CONNECT_CUSTOMER":
      ({shop_customer, social_customer} = action.payload);
      channel_customers = state.customers[social_customer.channel_id] || []

      return {
        ...state,
        selected_customer: {
          ...state.selected_customer, shop_customer: shop_customer
        },
        customers: {
          ...state.customers,
          [social_customer.channel_id]: channel_customers.map(el => (el.id === social_customer.id ? {...el, shop_customer: shop_customer} : el))
        },
        matched_shop_customers: []
      }
    case "DISCONNECT_CUSTOMER":
      social_customer = action.payload
      channel_customers = state.customers[social_customer.channel_id] || []

      return {
        ...state,
        selected_customer: {
          ...state.selected_customer, shop_customer: null
        },
        customers: {
          ...state.customers,
          [social_customer.channel_id]: channel_customers.map(el => (el.id === social_customer.id ? {...el, shop_customer: null} : el))
        },
        matched_shop_customers: []
      }
    case "MATCHED_SHOP_CUSTOMERS":
      return {
        ...state,
        matched_shop_customers: action.payload
      }
    case "CUSTOMER_HAS_MESSAGES":
      channel_customers = state.customers[state.selected_customer.channel_id] || []

      return {
        ...state,
        selected_customer: {
          ...state.selected_customer, has_more_messages: action.payload.has_more_messages
        },
        customers: {
          ...state.customers,
          [state.selected_customer.channel_id]: channel_customers.map(el => (el.id === state.selected_customer.id ? {...el, has_more_messages: action.payload.has_more_messages} : el))
        }
      }
    default:
      return state;
  }
}
