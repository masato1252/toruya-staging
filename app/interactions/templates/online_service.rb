# frozen_string_literal: true

require "message_encryptor"

module Templates
  class OnlineService < ActiveInteraction::Base
    object :online_service_customer_relation

    def execute
      action_templates = [
        LineActions::Uri.new(
          label: I18n.t("common.status_info"),
          url: customer_status_online_service_url,
          btn: "secondary"
        )
      ]

      if content_url
        action_templates.prepend(
          LineActions::Uri.new(
            label: I18n.t("action.online_service_actions.#{online_service.solution_type_for_message}"),
            url: content_url,
            btn: "primary"
          )
        )
      end

      LineMessages::FlexTemplateContent.video_description_card(
        picture_url: online_service.picture_url,
        content_url: content_url || customer_status_online_service_url,
        title: online_service.name,
        context: "#{I18n.t("common.type")}：#{I18n.t("user_bot.dashboards.online_service_creation.goals.#{online_service.goal_type}.title")}\n#{I18n.t("common.term")}：#{online_service_customer_relation.end_date_text}",
        action_templates: action_templates.map(&:template)
      )
    end

    private

    def content_url
      @content_url ||=
        if online_service.external?
          "#{online_service.content_url}?openExternalBrowser=1"
        elsif online_service.bundler?
          nil
        else
          Rails.application.routes.url_helpers.online_service_url(
            slug: online_service.slug,
            encrypted_social_service_user_id: MessageEncryptor.encrypt(social_customer.social_user_id)
          )
        end
    end

    def customer_status_online_service_url
      Rails.application.routes.url_helpers.customer_status_online_service_url(
        slug: online_service.slug,
        encrypted_social_service_user_id: MessageEncryptor.encrypt(social_customer.social_user_id)
      )
    end

    def online_service
      online_service_customer_relation.online_service
    end

    def social_customer
      online_service_customer_relation.customer.social_customer
    end
  end
end
