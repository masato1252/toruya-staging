class LineClient
  attr_reader :customer

  def initialize(social_customer)
    @social_customer = social_customer
  end

  def send(message)
    client.push_message(social_customer.social_user_id, {type: "text", text: message})
  end

  def reply(reply_token, message)
    client.reply_message(reply_token, message)
  end

  private

  def client
    social_customer.social_account.client
  end
end
