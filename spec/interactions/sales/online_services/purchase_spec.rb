# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::OnlineServices::Purchase do
  before { StripeMock.start }
  after { StripeMock.stop }

  let(:user) { FactoryBot.create(:access_provider, :stripe, user: sale_page.user).user }
  let(:sale_page) { FactoryBot.create(:sale_page, :online_service) }
  let(:customer) { FactoryBot.create(:social_customer, user: user).customer }
  let(:authorize_token) { StripeMock.create_test_helper.generate_card_token }
  let(:args) do
    {
      sale_page: sale_page,
      customer: customer,
      authorize_token: authorize_token
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when sale page was free" do
      it "create a free relation" do
        outcome

        relation = OnlineServiceCustomerRelation.where(online_service: sale_page.product, customer: customer).take
        expect(relation).to be_free_payment_state
        expect(relation).to be_active
        expect(relation.expire_at).to eq(sale_page.product.current_expire_time)
      end
    end

    context "when sale page was paid version" do
      let(:sale_page) { FactoryBot.create(:sale_page, :online_service, :paid_version) }
      it "create a paid relation" do
        outcome

        relation = OnlineServiceCustomerRelation.where(online_service: sale_page.product, customer: customer).take
        expect(relation).to be_paid_payment_state
        expect(relation).to be_active
        expect(relation.expire_at).to eq(sale_page.product.current_expire_time)
      end
    end
  end
end
