class LineClient
  COLUMNS_NUMBER_LIMIT = 10
  BUTTON_DESC_LIMIT = 60
  BUTTON_DESC_WITHOUT_IMAGE_LIMIT = 160
  BUTTON_TITLE_LIMIT = 40
  BUTTON_ACTIONS_SIZE_LIMIT = 4
  ALT_TEXT_LIMIT = 400

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

    response
  end

  def self.profile(social_customer)
    error_handler(__method__, social_customer.id) do
      new(social_customer).client.get_profile(social_customer.social_user_id)
    end
  end

  def self.flex(social_customer, template)
    error_handler(__method__, social_customer.id, template) do
      new(social_customer).client.push_message(social_customer.social_user_id, template)
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
        "altText": text.first(ALT_TEXT_LIMIT),
        "template": {
          "type": "buttons",
          "title": title.first(BUTTON_TITLE_LIMIT),
          "text": text.first(BUTTON_DESC_WITHOUT_IMAGE_LIMIT),
          "actions": actions.first(BUTTON_ACTIONS_SIZE_LIMIT)
        }
      })
    end
  end

  def self.carousel_template(social_customer: , text:, columns:)
    error_handler(__method__, social_customer.id, text, columns) do
      new(social_customer).client.push_message(social_customer.social_user_id, {
        "type": "template",
        "altText": text,
        "template": {
          "type": "carousel",
          "columns": columns.first(COLUMNS_NUMBER_LIMIT)
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
