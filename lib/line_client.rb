class LineClient
  attr_reader :social_customer

  def initialize(social_customer)
    @social_customer = social_customer
  end

  def self.error_handler(*args)
    response = yield

    if response.is_a?(Net::HTTPBadRequest)
      Rollbar.warning(
        "Line clinet Request failed",
        response: response.body,
        args: args
      )
    end
  end

  def self.profile(social_customer)
    error_handler(__method__, social_customer.id) do
      new(social_customer).client.get_profile(social_customer.social_user_id)
    end
  end

  def self.send(social_customer, message)
    error_handler(__method__, social_customer.id, message) do
      new(social_customer).client.push_message(social_customer.social_user_id, {type: "text", text: message})
    end
  end

  def self.reply(social_customer, reply_token, message)
    error_handler(__method__, social_customer.id, reply_token, message) do
      new(social_customer).client.reply_message(reply_token, message)
    end
  end

  def self.button_template(social_customer:, title:, text:, actions:)
    error_handler(__method__, social_customer.id, title, text, actions) do
      new(social_customer).client.push_message(social_customer.social_user_id, {
        "type": "template",
        "altText": text,
        "template": {
          "type": "buttons",
          "title": title,
          "text": text,
          "defaultAction": {
            "type": "uri",
            "label": "View detail",
            "uri": Rails.application.routes.url_helpers.webhooks_line_url(channel_id: social_customer.social_account.channel_id)
          },
          "actions": actions
        }
      })
    end
  end

  def self.carousel_template(social_customer: , title:, text:, columns:)
    error_handler(__method__, social_customer.id, title, text, columns) do
      new(social_customer).client.push_message(social_customer.social_user_id, {
        "type": "template",
        "altText": text,
        "template": {
          "type": "carousel",
          "columns": columns
        }
      })
    end
  end

  def social_account
    @social_account ||= social_customer.social_account
  end

  def client
    @client ||= social_account.client
  end
end
