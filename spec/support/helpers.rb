# frozen_string_literal: true

module Spec
  module Support
    module Helpers
      def url_helpers
        Rails.application.routes.url_helpers
      end
    end
  end
end

RSpec.configure do |config|
  config.include Spec::Support::Helpers
end
