# frozen_string_literal: true

module Notifiers
  module Customers
    module OnlineServices
      class ActiveRelations < Base
        deliver_by :line

        integer :last_relation_id, default: nil

        validate :receiver_should_be_customer

        def message
          if contents.blank?
            "No services"
          else
            LineMessages::FlexTemplateContainer.carousel_template(
              altText: "Your services",
              contents: contents
            ).to_json
          end
        end

        private

        def contents
          scope = receiver.online_service_customer_relations.includes(:online_service).order("online_service_customer_relations.id DESC")
          scope = scope.where("online_service_customer_relations.id < ?", last_relation_id) if last_relation_id
          relations = scope.limit(LineClient::COLUMNS_NUMBER_LIMIT + 1)

          if relations.size > LineClient::COLUMNS_NUMBER_LIMIT
            limited_relations = relations.first(LineClient::COLUMNS_NUMBER_LIMIT - 1)
            limited_relations.map do |relation|
              compose(Templates::OnlineService, online_service_customer_relation: relation)
            end.push(LineMessages::FlexTemplateContent.next_card(line_keyword: "利用中サービス #{limited_relations.last.id}"))
          else
            relations.map do |relation|
              compose(Templates::OnlineService, online_service_customer_relation: relation)
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
