# frozen_string_literal: true

require "line_client"
require "message_encryptor"

class Lines::Actions::CustomerDashboard < ActiveInteraction::Base
  object :social_customer

  def execute
    user = social_customer.social_account.user

    actions =[
      LineActions::Uri.new(
        label: I18n.t("line.bot.messages.customer_dashboard.details"),
        url: Rails.application.routes.url_helpers.reservations_lines_customers_dashboard_url(
          public_id: user.public_id,
          social_service_user_id: social_customer.social_user_id
        ),
        btn: "primary",
        key: social_customer.social_rich_menu_key
      )
    ]

    line_response = LineClient.flex(
      social_customer,
      ::LineMessages::FlexTemplateContainer.template(
        altText: I18n.t("line.bot.messages.customer_dashboard.message"),
        contents: ::LineMessages::FlexTemplateContent.title_button_card(
          title: I18n.t("line.bot.messages.customer_dashboard.message"),
          action_templates: actions.map(&:template)
        )
      )
    )

    if line_response.is_a?(Net::HTTPOK)
      compose(
        SocialMessages::Create,
        social_customer: social_customer,
        content: I18n.t("line.bot.messages.customer_dashboard.message"),
        readed: true,
        message_type: SocialMessage.message_types[:bot],
        send_line: false
      )
    end
  end
end
