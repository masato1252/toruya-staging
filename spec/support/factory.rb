# frozen_string_literal: true

module Spec
  module Support
    module Factory
      class ProductionLine
        include Singleton
        include ::RSpec::Mocks::ExampleMethods

        def create_payment(referral: nil)
          referral ||= create_referral

          Payments::ReferralFee.run!(
            referral: referral,
            charge: FactoryBot.create(:subscription_charge, :completed, user: referral.referrer)
          )
        end

        def create_referral(referee: nil, referrer: nil, state: :pending)
          referrer_plan =
            case state
            when :pending
              Plan.free_level.take
              when:active
              Plan.child_basic_level.take
            when :referrer_canceled
              Plan.basic_level.take
            end

          Referral.create(
            referee: referee || FactoryBot.create(:subscription, plan: Plan.business_level.take).user,
            referrer: referrer || FactoryBot.create(:subscription, plan: referrer_plan).user,
            state: state
          )
        end
      end

      def factory
        ProductionLine.instance
      end
    end
  end
end

RSpec.configure do |config|
  config.include Spec::Support::Factory
end
