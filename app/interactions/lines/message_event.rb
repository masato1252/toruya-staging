class Lines::MessageEvent < Lines::HandleEvent
  def execute
    message = {
      type: 'text',
      text: "hello message #{event[:message][:text]}"
    }

    reply_token = params['events'][0]['replyToken']
    client.reply_message(reply_token, message)
  end
end
