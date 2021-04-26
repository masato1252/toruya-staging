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

      LineMessages::FlexTemplateContent.content7(
        picture_url: product.thumbnail_url || sale_page.introduction_video_url,
        content_url: Rails.application.routes.url_helpers.online_service_url(slug: product.slug),
        title1: product.name,
        label: I18n.t("common.responsible_by"),
        context: sale_page.staff.name,
        action_templates: [
          LineActions::Uri.new(
            label: I18n.t("action.watch"),
            url: Rails.application.routes.url_helpers.online_service_url(slug: sale_page.product.slug, encrypted_social_service_user_id: MessageEncryptor.encrypt(social_customer.social_user_id)),
            btn: "primary"
          )
        ].map(&:template)
      )
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
      compose(
        SocialMessages::Create,
        social_customer: social_customer,
        content: "Your services",
        readed: true,
        message_type: SocialMessage.message_types[:bot],
        send_line: false
      )

      LineClient.flex(
        social_customer,
        LineMessages::FlexTemplateContainer.carousel_template(
          altText: "Your services",
          contents: contents
        )
      )
    end
  end

  private

  def customer
    @customer ||= social_customer.customer
  end
end
