# frozen_string_literal: true

require "message_encryptor"

module Templates
  class OnlineService < ActiveInteraction::Base
    object :sale_page
    object :online_service
    object :social_customer

    def execute
      LineMessages::FlexTemplateContent.content7(
        picture_url: online_service.picture_url,
        content_url: Rails.application.routes.url_helpers.online_service_url(slug: online_service.slug),
        title1: online_service.name,
        label: I18n.t("common.responsible_by"),
        context: sale_page.staff.name,
        action_templates: [
          LineActions::Uri.new(
            label: I18n.t("action.online_service_actions.#{online_service.solution_type_for_message}"),
            url: Rails.application.routes.url_helpers.online_service_url(slug: online_service.slug, encrypted_social_service_user_id: MessageEncryptor.encrypt(social_customer.social_user_id)),
            btn: "primary"
          )
        ].map(&:template)
      )
    end
  end
end
