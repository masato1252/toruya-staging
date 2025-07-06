# frozen_string_literal: true

module Notifiers
  module Customers
    module OnlineServices
      class ActiveRelations < Base
        integer :bundler_service_id, default: nil
        integer :last_relation_id, default: nil

        validate :receiver_should_be_customer

        def message
          if contents.blank?
            I18n.t("line.bot.messages.online_services.no_services")
          else
            ::LineMessages::FlexTemplateContainer.carousel_template(
              altText: I18n.t("line.bot.keywords.services"),
              contents: contents
            ).to_json
          end
        end

        private

        def contents
          @contents ||=
            begin
              scope = receiver.online_service_customer_relations.includes(:online_service).order("online_service_customer_relations.id DESC")
              scope = scope.where("online_service_customer_relations.id < ?", last_relation_id) if last_relation_id
              if bundler_service_id.present? && bundler_service = OnlineService.find_by(id: bundler_service_id)
                scope = scope.where(online_service_id: bundler_service.bundled_services.pluck(:online_service_id))
              end

              relations = scope.limit(LineClient::COLUMNS_NUMBER_LIMIT + 1)
              relations = relations.to_a.filter {|re| re.accessible? || re.available? }

              if relations.size > LineClient::COLUMNS_NUMBER_LIMIT
                limited_relations = relations.first(LineClient::COLUMNS_NUMBER_LIMIT - 1)

                line_keyword =
                  if bundler_service
                    "#{I18n.t("line.bot.keywords.services")} #{Lines::MessageEvent::BUNDLER_SERVICE_SEPARATOR}#{bundler_service_id}#{Lines::MessageEvent::BUNDLER_SERVICE_SEPARATOR} #{limited_relations.last.id}"
                  else
                    "#{I18n.t("line.bot.keywords.services")} #{limited_relations.last.id}"
                  end

                limited_relations.map do |relation|
                  compose(Templates::OnlineService, online_service_customer_relation: relation)
                end.push(::LineMessages::FlexTemplateContent.next_card(
                    action_template: LineActions::Message.template(
                    text: "#{I18n.t("common.more")} - #{line_keyword}",
                    label: "More"
                  )))
              else
                relations.map do |relation|
                  compose(Templates::OnlineService, online_service_customer_relation: relation)
                end
              end
            end
        end

        def content_type
          if contents.blank?
            SocialUserMessages::Create::TEXT_TYPE
          else
            SocialUserMessages::Create::FLEX_TYPE
          end
        end
      end
    end
  end
end
