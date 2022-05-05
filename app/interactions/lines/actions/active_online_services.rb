# frozen_string_literal: true

require "line_client"

class Lines::Actions::ActiveOnlineServices < ActiveInteraction::Base
  object :social_customer

  def execute
    unless customer
      compose(Lines::Menus::Guest, social_customer: social_customer)

      return
    end

    contents = customer.online_service_customer_relations.includes(:online_service, sale_page: [:staff]).limit(LineClient::COLUMNS_NUMBER_LIMIT).map do |relation|
      sale_page = relation.sale_page
      product = relation.online_service

      compose(Templates::OnlineService, sale_page: sale_page, online_service: product, social_customer: social_customer)
    end

    if contents.blank?
      compose(
        SocialMessages::Create,
        social_customer: social_customer,
        content: "No services",
        readed: true,
        message_type: SocialMessage.message_types[:bot]
      )
    else
      line_response = LineClient.flex(
        social_customer,
        LineMessages::FlexTemplateContainer.carousel_template(
          altText: "Your services",
          contents: contents
        )
      )

      if line_response.is_a?(Net::HTTPOK)
        compose(
          SocialMessages::Create,
          social_customer: social_customer,
          content: "Your services",
          readed: true,
          message_type: SocialMessage.message_types[:bot],
          send_line: false
        )
      end
    end
  end

  private

  def customer
    @customer ||= social_customer.customer
  end
end
