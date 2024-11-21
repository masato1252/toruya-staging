# frozen_string_literal: true

require "line_client"
require "message_encryptor"

class Lines::Actions::Contact < ActiveInteraction::Base
  object :social_customer

  def execute
    user = social_customer.social_account.user

    actions =
      if user.shops.count == 1 || user.shops.pluck(:phone_number).uniq.count == 1
        if user.shops.first.phone_number&.gsub(/\D/, '').present?
          [
            LineActions::Uri.new(
              label: I18n.t("action.call"),
              url: "tel:#{user.shops.first.phone_number.gsub(/\D/, '')}",
              btn: "secondary",
              key: social_customer.social_rich_menu_key
            )
          ]
        else
          []
        end
      else
        user.shops.map do |shop|
          if shop.phone_number&.gsub(/\D/, '').present?
            LineActions::Uri.new(
              label: "#{shop.short_name}#{I18n.t("action.call")}",
              url: "tel:#{shop.phone_number.gsub(/\D/, '')}",
              btn: "secondary",
              key: social_customer.social_rich_menu_key
            )
          end
        end.compact
      end

    actions.unshift(
      LineActions::Uri.new(
        label: I18n.t("action.send_message"),
        url: Rails.application.routes.url_helpers.lines_contacts_url(encrypted_social_service_user_id: MessageEncryptor.encrypt(social_customer.social_user_id)),
        btn: "secondary",
        key: social_customer.social_rich_menu_key
      )
    )

    line_response = LineClient.flex(
      social_customer,
      ::LineMessages::FlexTemplateContainer.template(
        altText: I18n.t("line.bot.messages.contact.contact_us"),
        contents: ::LineMessages::FlexTemplateContent.two_header_card(
          title1: I18n.t("line.bot.messages.contact.contact_us"),
          title2: I18n.t("line.bot.messages.contact.contact_us_with_text_or_phone"),
          action_templates: actions.map(&:template)
        )
      )
    )

    if line_response.is_a?(Net::HTTPOK)
      compose(
        SocialMessages::Create,
        social_customer: social_customer,
        content: I18n.t("line.bot.messages.contact.contact_us"),
        readed: true,
        message_type: SocialMessage.message_types[:bot],
        send_line: false
      )
    end
  end
end
