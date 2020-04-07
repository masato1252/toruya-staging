class Lines::FollowEvent < Lines::HandleEvent
  def execute
    message = {
      type: 'text',
      text: "hello User #{event[:source][:userId]}"
    }

    reply_token = params['events'][0]['replyToken']
    client.reply_message(reply_token, message)
  end
end
