class LineClient
  attr_reader :social_customer

  def initialize(social_customer)
    @social_customer = social_customer
  end

  def self.send(social_customer, message)
    new(social_customer).client.push_message(social_customer.social_user_id, {type: "text", text: message})
  end

  def self.reply(social_customer, reply_token, message)
    new(social_customer).client.reply_message(reply_token, message)
  end

  def client
    social_customer.social_account.client
  end
end
