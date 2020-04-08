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

  def self.button_template(social_customer:, title:, text:, actions:)
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

  def self.carousel_template(social_customer: , title:, text:, columns:)
    new(social_customer).client.push_message(social_customer.social_user_id, {
      "type": "template",
      "altText": text,
      "template": {
        "type": "carousel",
        "columns": columns
      }
    })
  end

  def social_account
    @social_account ||= social_customer.social_account
  end

  def client
    @client ||= social_account.client
  end
end
