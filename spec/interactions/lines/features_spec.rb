require "rails_helper"

RSpec.describe Lines::Features do
  let(:social_customer) { FactoryBot.create(:social_customer) }
  let(:args) do
    {
      social_customer: social_customer
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when social_customer connected with customer" do
      it "calls Lines::Menus::OnlineBookingFeatures" do
        expect(Lines::Menus::OnlineBookingFeatures).to receive(:run).with(social_customer: social_customer).and_return(spy(invalid?: false))

        outcome
      end
    end

    context "when social_customer doesn't connect with customer" do
      let(:social_customer) { FactoryBot.create(:social_customer, customer: nil) }

      it "calls Lines::Menus::Guest" do
        expect(Lines::Menus::Guest).to receive(:run).with(social_customer: social_customer).and_return(spy(invalid?: false))

        outcome
      end
    end
  end
end
