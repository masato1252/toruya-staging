# frozen_string_literal: true

require "translator"

module Notifiers
  module Customers
    module Surveys
      class ActivityCanceledResponse < Base
        object :survey_response

        validate :receiver_should_be_customer

        def execute
          I18n.with_locale(receiver.locale) do
            super
          end
        end

        private

        def message
          template = compose(
            ::CustomMessages::Customers::Template,
            product: survey_response.survey_activity,
            scenario: ::CustomMessages::Customers::Template::ACTIVITY_CANCELED_RESPONSE,
          )

          Translator.perform(template, survey_response.message_template_variables(receiver))
        end
      end
    end
  end
end
