import _ from "lodash";

// mapping with
// app/serializers/message_serializer.rb
//
// @messages:
// {
//   <customer_id> => [
//      {
//        id: <message_id>,
//        message_type: bot|staff||customer|customer_reply_bot
//        customer_id: <customer_id>,
//        text: <message content>,
//        readed: true|false,
//        created_at: <Datetime>
//        formatted_created_at: <String>
//      },
//   ]
// }

const initialState = {
  messages: {},
  reply_message: "",
  reply_images: [],
  reply_image_urls: []
}

export default (state = initialState, action) => {
  switch(action.type) {
    case "PREPEND_MESSAGES":
      const new_messages = [...action.payload.messages, ...(state.messages[action.payload.customer_id] || [])]

      return {
        ...state,
        messages: {
          ...state.messages,
          [action.payload.customer_id]: _.uniqWith(new_messages, (a, b) => a.id === b.id)
        }
      }
    case "STAFF_NEW_MESSAGE":
      return {
        ...state,
        messages: {
          ...state.messages,
          [action.payload.customer_id]: [...(state.messages[action.payload.customer_id] || []), action.payload.message]
        }
      }
    case "CUSTOMER_NEW_MESSAGE":
      return {
        ...state,
        messages: {
          ...state.messages,
          [action.payload.customer.id]: [...(state.messages[action.payload.customer.id] || []), action.payload.message]
        }
      }
    case "REPLY_MESSAGE":
      return {
        ...state,
        reply_message: action.payload.reply_message
      }
    case "REPLY_IMAGE_MESSAGE":
      return {
        ...state,
        reply_images: action.payload.reply_images
      }
    case "REPLY_IMAGE_URL_MESSAGE":
      return {
        ...state,
        reply_image_urls: action.payload.reply_image_urls
      }
    case "AI_QUESTION":
      return {
        ...state,
        ai_question: action.payload.ai_question
      }
    default:
      return state;
  }
}
