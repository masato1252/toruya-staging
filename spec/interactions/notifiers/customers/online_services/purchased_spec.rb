# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::Customers::OnlineServices::Purchased, :with_line do
  let(:receiver) { FactoryBot.create(:social_customer, customer: relation.customer).customer }
  let(:relation) { FactoryBot.create(:online_service_customer_relation) }
  let(:args) do
    {
      receiver: receiver,
      online_service: relation.online_service
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "sends line" do
      online_service = relation.online_service
      template = ::CustomMessages::Customers::Template.run!(product: online_service, scenario: ::CustomMessages::Customers::Template::ONLINE_SERVICE_PURCHASED)
      content = Translator.perform(template, online_service.message_template_variables(receiver))
      expect(LineClient).to receive(:send).with(receiver.social_customer, content)
      expect(CustomMessages::Customers::Next).to receive(:run).with({
        product: online_service,
        scenario: ::CustomMessages::Customers::Template::ONLINE_SERVICE_PURCHASED,
        receiver: receiver
      })

      expect {
        outcome
      }.to change {
        SocialMessage.where(
          social_customer: receiver.social_customer,
          raw_content: content
        ).count
      }.by(1)
    end
  end
end
