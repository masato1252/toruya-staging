# frozen_string_literal: true

require "utils"

class LineClient
  COLUMNS_NUMBER_LIMIT = 10
  BUTTON_DESC_LIMIT = 60
  BUTTON_DESC_WITHOUT_IMAGE_LIMIT = 160
  BUTTON_TITLE_LIMIT = 40
  BUTTON_ACTIONS_SIZE_LIMIT = 4
  ALT_TEXT_LIMIT = 400

  def self.error_handler(*args)
    response = yield

    if !response.is_a?(Net::HTTPSuccess)
      Rollbar.error(
        "Line client Request failed",
        response: response&.body,
        args: args,
        backtrace: caller
      )
    end

    response
  end

  # TODO: SocialCustomer or Social User or User
  def self.profile(social_customer)
    error_handler(__method__, social_customer.id) do
      social_customer.client&.get_profile(social_customer.social_user_id)
    end
  end

  def self.flex(social_customer, template)
    error_handler(__method__, social_customer.id, template) do
      parsed_template =
        begin
          JSON.parse(template)
        rescue TypeError, JSON::ParserError
          template
        end

      social_customer.client.push_message(social_customer.social_user_id, parsed_template)
    end
  end

  def self.send(social_customer, message)
    error_handler(__method__, social_customer.id, message) do
      social_customer.client&.push_message(social_customer.social_user_id, {type: "text", text: message})
    end
  end

  def self.send_video(social_customer, raw_message)
    error_handler(__method__, social_customer.id, raw_message) do
      message = JSON.parse(raw_message)

      social_customer.client.push_message(
        social_customer.social_user_id,
        {
          type: "video",
          originalContentUrl: message["originalContentUrl"],
          previewImageUrl: message["previewImageUrl"]
        }
      )
    end
  end

  def self.send_image(social_customer, raw_message)
    error_handler(__method__, social_customer.id, raw_message) do
      message = JSON.parse(raw_message)

      social_customer.client.push_message(
        social_customer.social_user_id,
        {
          type: "image",
          originalContentUrl: message["originalContentUrl"],
          previewImageUrl: message["previewImageUrl"]
        }
      )
    end
  end

  def self.reply(social_customer, reply_token, message)
    error_handler(__method__, social_customer.id, reply_token, message) do
      social_customer.client.reply_message(reply_token, message)
    end
  end

  def self.button_template(social_customer:, title:, text:, actions:)
    error_handler(__method__, social_customer.id, title, text, actions) do
      social_customer.client.push_message(social_customer.social_user_id, {
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
      social_customer.client.push_message(social_customer.social_user_id, {
        "type": "template",
        "altText": text,
        "template": {
          "type": "carousel",
          "columns": columns.first(COLUMNS_NUMBER_LIMIT)
        }
      })
    end
  end

  def self.create_rich_menu(social_account:, body:)
    #TODO: handle error response
    social_account.client.create_rich_menu(body)
  end

  def self.create_rich_menu_image(social_account:, rich_menu_id:, file_path: )
    if file_path.match?(/http/)
      error_handler(__method__, social_account.id, rich_menu_id, file_path) do
        tempfile = Utils.file_from_url(file_path)
        rsp = social_account.client.create_rich_menu_image(rich_menu_id, tempfile)
        tempfile.close
        rsp
      end
    else
      File.open(file_path, "r") do |file|
        social_account.client.create_rich_menu_image(rich_menu_id, file)
      end
    end
  end

  def self.set_default_rich_menu(social_rich_menu)
    error_handler(__method__, social_rich_menu.id) do
      social_rich_menu.account.client.set_default_rich_menu(social_rich_menu.social_rich_menu_id)
    end
  end

  def self.delete_rich_menu(social_rich_menu)
    error_handler(__method__, social_rich_menu.id) do
      social_rich_menu.account.client.delete_rich_menu(social_rich_menu.social_rich_menu_id)
    end
  end

  # social_customer: SocialCustomer or SocialUser object
  def self.link_rich_menu(social_customer:, social_rich_menu:)
    error_handler(__method__, social_customer.id, social_rich_menu.id) do
      social_customer.client.link_user_rich_menu(social_customer.social_user_id, social_rich_menu.social_rich_menu_id)
    end
  end

  def self.unlink_rich_menu(social_customer:)
    error_handler(__method__, social_customer.id) do
      social_customer.client&.unlink_user_rich_menu(social_customer.social_user_id)
    end
  end

  def self.message_content(social_customer:, message_id:)
    error_handler(__method__, social_customer.id, message_id) do
      social_customer.client.get_message_content(message_id)
    end
  end
end
