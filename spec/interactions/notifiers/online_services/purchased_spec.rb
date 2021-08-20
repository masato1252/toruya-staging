# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::OnlineServices::Purchased do
  let(:receiver) { FactoryBot.create(:social_customer, customer: relation.customer).customer }
  let(:sale_page) { FactoryBot.create(:sale_page, product: relation.online_service, user: receiver.user) }
  let(:relation) { FactoryBot.create(:online_service_customer_relation) }
  let(:args) do
    {
      receiver: receiver,
      sale_page: sale_page
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "sends line" do
      online_service = sale_page.product
      template = CustomMessage.template_of(online_service, CustomMessage::ONLINE_SERVICE_PURCHASED)
      content = Translator.perform(template, online_service.message_template_variables(receiver))
      expect(LineClient).to receive(:send).with(receiver.social_customer, content)
      expect(CustomMessages::Next).to receive(:run).with({
        product: sale_page.product,
        scenario: CustomMessage::ONLINE_SERVICE_PURCHASED,
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
