# frozen_string_literal: true

require "translator"

module Notifiers
  class Broadcast < Base
    deliver_by :line
    object :broadcast

    def message
      Translator.perform(broadcast.content, { customer_name: customer.name })
    end
  end
end
