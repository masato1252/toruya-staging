require "line_client"

class Lines::Actions::Contact < ActiveInteraction::Base
  object :social_customer

  def execute
    user = social_customer.social_account.user

    actions =
      if user.shops.count == 1 || user.shops.pluck(:phone_number).uniq.count == 1
        [
          LineActions::Uri.new(
            label: I18n.t("action.call"),
            url: "tel:#{user.shops.first.phone_number}",
            btn: "secondary"
          )
        ]
      else
        user.shops.map do |shop|
          LineActions::Uri.new(
            label: "#{shop.short_name}#{I18n.t("action.call")}",
            url: "tel:#{shop.phone_number}",
            btn: "secondary"
          )
        end
      end

    actions.unshift(
      LineActions::Uri.new(
        label: I18n.t("action.send_message"),
        url: Rails.application.routes.url_helpers.lines_contacts_url(encrypted_social_service_user_id: MessageEncryptor.encrypt(social_customer.social_user_id)),
        btn: "secondary"
      )
    )

    compose(
      SocialMessages::Create,
      social_customer: social_customer,
      content: I18n.t("line.bot.messages.contact.contact_us"),
      readed: true,
      message_type: SocialMessage.message_types[:bot],
      send_line: false
    )

    LineClient.flex(
      social_customer,
      LineMessages::FlexTemplateContainer.template(
        altText: I18n.t("line.bot.messages.contact.contact_us"),
        contents: LineMessages::FlexTemplateContent.content5(
          title1: I18n.t("line.bot.messages.contact.contact_us"),
          title2: I18n.t("line.bot.messages.contact.contact_us_with_text_or_phone"),
          action_templates: actions.map(&:template)
        )
      )
    )
  end
end
