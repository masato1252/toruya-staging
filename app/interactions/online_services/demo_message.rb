# frozen_string_literal: true

module OnlineServices
  class DemoMessage < ActiveInteraction::Base
    object :online_service

    def execute
      LineClient.flex(
        online_service.user.social_user,
        LineMessages::FlexTemplateContainer.template(
          altText: I18n.t("notifier.online_service.purchased.#{online_service.solution_type_for_message}.message", service_title: online_service.name),
          contents:
          LineMessages::FlexTemplateContent.content8(
            picture_url: online_service.picture_url,
            content_url: Rails.application.routes.url_helpers.online_service_url(slug: online_service.slug),
            title: online_service.name,
            context: online_service.message_template&.content || online_service.name,
            action_templates: [
              LineActions::Uri.new(
                label: I18n.t("user_bot.dashboards.services.form.demo_button"),
                url: Rails.application.routes.url_helpers.online_service_url(slug: online_service.slug),
                btn: "secondary"
              )
            ].map(&:template)
          )
        )
      )
    end
  end
end
