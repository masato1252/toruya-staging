# frozen_string_literal: true

module Notifiers
  module Customers
    module OnlineServices
      class ActiveRelations < Base
        deliver_by :line

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
          receiver.online_service_customer_relations.includes(:online_service).limit(LineClient::COLUMNS_NUMBER_LIMIT).map do |relation|
            compose(Templates::OnlineService, online_service_customer_relation: relation)
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
