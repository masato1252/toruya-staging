# frozen_string_literal: true

require "message_encryptor"

module Templates
  class Episode < ActiveInteraction::Base
    object :episode
    object :social_customer

    def execute
      ::LineMessages::FlexTemplateContent.video_description_card(
        picture_url: episode.thumbnail_url || online_service.picture_url,
        content_url: content_url,
        title: episode.name,
        context: episode.note.presence || episode.name,
        action_templates: [
          LineActions::Uri.new(
            label: I18n.t("action.online_service_actions.#{episode.solution_type}"),
            url: content_url,
            btn: "primary",
            key: social_customer.social_rich_menu_key
          )
        ].map(&:template)
      )
    end

    private

    def online_service
      @online_service ||= episode.online_service
    end

    def content_url
      @content_url ||= Rails.application.routes.url_helpers.online_service_url(
        slug: online_service.slug,
        episode_id: episode.id,
        encrypted_social_service_user_id: MessageEncryptor.encrypt(social_customer.social_user_id)
      )
    end
  end
end
