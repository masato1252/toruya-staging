require "rails_helper"

RSpec.describe Subscriptions::ManualCharge do
  let(:args) do
    {
      subscription: subscription,
      plan: plan
      authorize_token: authorize_token
    }
  end
  describe "#execute" do
  end
end
