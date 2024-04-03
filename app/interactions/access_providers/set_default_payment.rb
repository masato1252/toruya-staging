# frozen_string_literal: true

module AccessProviders
  class SetDefaultPayment < ActiveInteraction::Base
    object :access_provider

    def execute
      access_provider.with_lock do
        owner.access_providers.payment.update(default_payment: false)
        access_provider.update(default_payment: true)
      end
    end

    private

    def owner
      @owner ||= access_provider.user
    end
  end
end
